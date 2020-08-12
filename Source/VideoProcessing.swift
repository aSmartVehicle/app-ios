//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  VideoProcessing.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import UIKit
import AVFoundation
import Vision
import CoreML

// *******************************************************************


struct VideoProcessingTiming {
    var t_videoframe: UInt64 = 0
    var t_processing_start: UInt64 = 0
    var t_processing_end: UInt64 = 0
    var t_preprocessing_start: UInt64 = 0
    var t_preprocessing_end: UInt64 = 0
    var t_save_start: UInt64 = 0
    var t_save_end: UInt64 = 0
    var t_inference_start: UInt64 = 0
    var t_inference_end: UInt64 = 0
    var t_detect_start: UInt64 = 0
    var t_detect_end: UInt64 = 0
    var t_display_start: UInt64 = 0
    var t_display_end: UInt64 = 0
}

// *******************************************************************

struct VideoProcessorSettings: Codable   {
    var maxFps = 100

    var scaledWidth: Int = 160
    var scaledHeight: Int = 120

    var croppingRect = CGRect(x: 0, y: 40, width: 160, height: 50)
    
    var steeringPredictionThreshold: Double = 0.1
    var slowThrottle: Float = 0.1
}

// *******************************************************************

private extension Dictionary where Key == UUID {
    mutating func insert(_ value: Value) -> UUID {
        let id = UUID()
        self[id] = value
        return id
    }
}

// *******************************************************************

class VideoProcessor: VideoSourceDelegate, ObservableObject {
    static let sharedInstance = VideoProcessor()
    var settings = VideoProcessorSettings()
    let car: Car
    let datastore: Datastore

    var isSaveTrainingData = false
    var isInference = false
    private var isDetectLed = false
    private var ledDetectionObservations = [UUID : (VideoProcessor, Bool, VideoProcessingTiming) -> Void]()
    var thresholdRed: Double = 0.0
    var thresholdGreen: Double = 0.0
    var thresholdBlue: Double = 0.7

    var averageFps = FpsAveraging()
    var model = autodriver()
    private let videoQueue: DispatchQueue
    private let videoSource = VideoSource()
    private let ciContext = CIContext(options: [.workingColorSpace: kCFNull!])
    private var scaledPixelBuffer: CVPixelBuffer?
    private var croppedPixelBuffer: CVPixelBuffer?
    

    // ***** UI-observable properties *****

    private(set) var scaledUiImage: UIImage? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var croppedUiImage: UIImage? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var steeringCategorical: ( index: Int, array: [Double] ) = (index: -1, []) {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var detectedLed: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }


    // ***** Lifecycle: init and start/stop *****

    private init(car: Car = Car.sharedInstance, datastore: Datastore = Datastore.sharedInstance) {
        self.car = car
        self.datastore = datastore
        videoQueue = DispatchQueue(label: "VideoQueue", qos: .default)
        videoSource.setDelegate(delegate: self, queue: videoQueue)

        // allocate pixel buffers
        let scaleStatus = CVPixelBufferCreate(nil, settings.scaledWidth, settings.scaledHeight,
                                              kCVPixelFormatType_32ARGB, nil,
                                              &self.scaledPixelBuffer)  // kCVPixelFormatType_24BGR kCVPixelFormatType_24RGB kCVPixelFormatType_32BGRA
        if scaleStatus != kCVReturnSuccess {
            fatalError("Error: could not create scaled pixel buffer - \(scaleStatus)")
        }
        let cropStatus = CVPixelBufferCreate(nil, Int(settings.croppingRect.width), Int(settings.croppingRect.height),
                                             kCVPixelFormatType_32ARGB, nil,
                                             &self.croppedPixelBuffer)
        if cropStatus != kCVReturnSuccess {
            fatalError("Error: could not create cropped pixel buffer - \(cropStatus)")
        }
    }


    func start(isSaveTrainingData: Bool, isInference: Bool, isDetectColor: Bool) {
        print("Starting VideoProcessor(\(isSaveTrainingData), \(isInference), \(isDetectColor)) with settings=\(settings)")
        self.isSaveTrainingData = isSaveTrainingData
        self.isInference = isInference
        self.isDetectLed = isDetectColor
        averageFps.reset()
        videoSource.start(maxFps: settings.maxFps)
    }

    func stop() {
        print("Stopping VideoProcessor")
        videoSource.stop()
    }


    // ***** Helper *****

    @discardableResult
    func observeLedDetection(using closure: @escaping (VideoProcessor, Bool, VideoProcessingTiming) -> Void) -> ObservationToken {
        let id = ledDetectionObservations.insert(closure)

        return ObservationToken { [weak self] in
            self?.ledDetectionObservations.removeValue(forKey: id)
        }
    }


    private func multiArrayAsArray(multiArray: MLMultiArray) -> [Double] {
        if multiArray.dataType != MLMultiArrayDataType.double {
            return []
        }
        if multiArray.shape.count != 1 {
            return []
        }
        let multiArrayPtr = multiArray.dataPointer.bindMemory(to: Double.self, capacity: multiArray.count)
        let buffer = UnsafeBufferPointer(start: multiArrayPtr, count: multiArray.count)
        let array = Array(buffer)
        return array
    }
    
    
    private func argmax(array: [Double]) -> (Int, Double) {
        var maxIndex = 0
        var maxValue: Double = array[0]
        for i in 1..<array.count where array[i] > maxValue {
          maxValue = array[i]
          maxIndex = i
        }
        return (maxIndex, maxValue)
    }


    // ***** Video capture *****

    func videoCapture(_ videoSource: VideoSource, pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        let t_processing_start = getTimeNanos()
        let t_timestamp = UInt64(CMTimeGetSeconds(timestamp)*1e9)
        averageFps.update()

        guard let _/*scaledPixelBuffer*/ = self.scaledPixelBuffer,
            let croppedPixelBuffer = self.croppedPixelBuffer else {
            print("Error: pixelBuffer not available")
            return
        }

        // preprocessing
        // recommendation: avoid CoreImage https://nshipster.com/image-resizing/
        let t_preprocessing_start = getTimeNanos()
        let scaledCgImage = scaleImage(pixelBuffer: pixelBuffer, width: settings.scaledWidth, height: settings.scaledHeight)
        let croppedCgImage = cropImage(cgImage: scaledCgImage, croppingRect: settings.croppingRect)
        renderToPixelBuffer(cgImage: croppedCgImage, outPixelBuffer: croppedPixelBuffer)
        let t_preprocessing_end = getTimeNanos()

        // save image (if applicable)
        let t_save_start = getTimeNanos()
        if isSaveTrainingData {
            if let steering = car.manualSteering, let throttle = car.manualThrottle {
                //observations.newImageForProcessing.values.forEach { closure in
                //    closure(self, scaledCgImage!, steering ?? 0, throttle ?? 0, t_timestamp)
                //}
                datastore.recordTrainingData(cgImage: scaledCgImage!, steering: steering, throttle: throttle, timestampInMs: t_timestamp/1000/1000)
            }
        }
        let t_save_end = getTimeNanos()

        // inference
        let t_inference_start = getTimeNanos()
        // sets steeringCategorical
        let (autoSteering, autoThrottle) = predict(isInference: isInference, pixelBuffer: croppedPixelBuffer, defaultThrottle: car.manualThrottle)
        car.set(autoSteering: autoSteering, autoThrottle: autoThrottle)
        let t_inference_end = getTimeNanos()

        // color detection
        let t_detect_start = getTimeNanos()
        var avgColor: UIColor = UIColor.black
        if (isDetectLed) {
            // CoreImage based implementation
            avgColor = getAverageColor(cgImage: scaledCgImage) ?? UIColor.black
            detectedLed = (avgColor.cgColor.components![0] >= CGFloat(thresholdRed)) && (avgColor.cgColor.components![1] >= CGFloat(thresholdGreen)) && (avgColor.cgColor.components![2] >= CGFloat(thresholdBlue))
        }
        let t_detect_end = getTimeNanos()

        // display images
        let t_display_start = getTimeNanos()
        scaledUiImage = UIImage(cgImage: scaledCgImage!)
        croppedUiImage = UIImage(cgImage: croppedCgImage!)
        let t_display_end = getTimeNanos()

        // the end
        let t_processing_end = getTimeNanos()

        // measurements
        if (isDetectLed) {
            let detectedLed = self.detectedLed
            let timing = VideoProcessingTiming(t_videoframe: t_timestamp, t_processing_start: t_processing_start, t_processing_end: t_processing_end, t_preprocessing_start: t_preprocessing_start, t_preprocessing_end: t_preprocessing_end, t_save_start: t_save_start, t_save_end: t_save_end, t_inference_start: t_inference_start, t_inference_end: t_inference_end, t_detect_start: t_detect_start, t_detect_end: t_detect_end, t_display_start: t_display_start, t_display_end: t_display_end)
            ledDetectionObservations.values.forEach { closure in
                closure(self, detectedLed, timing)
            }
        }
    }

    
    private func scaleImage(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let sx = CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let sy = CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        let scaleTransform = CGAffineTransform(scaleX: sx, y: sy)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        //ciContext.render(scaledImage, to: scaledPixelBuffer)
        let scaledCgImage = self.ciContext.createCGImage(scaledImage, from: scaledImage.extent)
        return scaledCgImage
    }
    
    
    private func cropImage(cgImage: CGImage?, croppingRect: CGRect) -> CGImage? {
        guard let cgImage = cgImage else {
            print("Error: cropImage input image not available")
            return nil
        }
        let croppedCgImage = cgImage.cropping(to: settings.croppingRect)
        return croppedCgImage
    }
    
    
    private func renderToPixelBuffer(cgImage: CGImage?, outPixelBuffer: CVPixelBuffer?) {
        guard let cgImage = cgImage else {
            print("Error: renderToPixelBuffer input image not available")
            return
        }
        guard let outPixelBuffer = outPixelBuffer else {
            print("Error: renderToPixelBuffer outPixelBuffer not available")
            return
        }
        ciContext.render(CIImage(cgImage: cgImage), to: outPixelBuffer)
    }


    private func predict(isInference: Bool, pixelBuffer: CVPixelBuffer, defaultThrottle: Float?) -> (Float?, Float?) {
        if (isInference) {
            do {
                let prediction = try model.prediction(img_in: pixelBuffer)
                let steeringCategoricalMl = prediction.output1
                let array = multiArrayAsArray(multiArray: steeringCategoricalMl)
                let (indexMax, valueMax) = argmax(array: array)
                steeringCategorical = (index: indexMax, array: array)
                let mid = array.count / 2
                let steering = Float(indexMax - mid) / Float(mid)
                let throttle = defaultThrottle
                if (valueMax >= settings.steeringPredictionThreshold) {
                    return (steering, throttle)
                } else {
                    return (steering, min(throttle ?? 0, settings.slowThrottle))
                }
            } catch let error as NSError {
                print("CarController.videoCapture: Error executing predictor \(error)")
            }
        }
        // inference is off or error
        return (nil, nil)
    }

    private func getAverageColor(cgImage: CGImage?) -> UIColor? {
        // inspired by https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
        guard let cgImage = cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let x = ciImage.extent.origin.x + ciImage.extent.size.width/3
        let y = ciImage.extent.origin.y + ciImage.extent.size.height/3
        let extentVector = CIVector(x: x, y: y, z: ciImage.extent.size.width/3, w: ciImage.extent.size.height/3)

        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        //let context = CIContext(options: [.workingColorSpace: kCFNull])
        ciContext.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }

}
