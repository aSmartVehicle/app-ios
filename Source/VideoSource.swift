//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  VideoSource.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

// based on https://github.com/hollance/YOLO-CoreML-MPSNNGraph by Matthijs Hollemans

import UIKit
import AVFoundation
import CoreVideo


// *******************************************************************

public protocol VideoSourceDelegate: class {
    func videoCapture(_ videoSource: VideoSource, pixelBuffer: CVPixelBuffer, timestamp: CMTime)
}

// *******************************************************************

public class VideoSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private(set) var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var lastTimestamp = CMTime()
    private weak var delegate: VideoSourceDelegate?

    var maxFps: Int = 30


    override init() {
        super.init()
        if isCameraAccessOk() {
            setupCaptureSession()
        }
    }


    private func isCameraAccessOk() -> Bool {
        // check camera access
        var allowedAccess = false
        let blocker = DispatchGroup()
        blocker.enter()
        AVCaptureDevice.requestAccess(for: .video) { flag in
            allowedAccess = flag
            blocker.leave()
        }
        blocker.wait()

        if !allowedAccess {
            print("!!! NO ACCESS TO CAMERA")
        }
        
        return allowedAccess
    }


    private func setupCaptureSession() {
        // choose a capture device
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices

        var captureDeviceInput: AVCaptureDeviceInput? = nil
        if let captureDevice = availableDevices.first {
            captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        }
        guard captureDeviceInput != nil else {
            print("Error: Could not create AVCaptureDeviceInput")
            return
        }

        // create the capture session
        captureSession = AVCaptureSession()
        captureSession!.beginConfiguration()
        captureSession!.sessionPreset = .hd1280x720 //.vga640x480 //hd1280x720

        // add input: capture device
        captureSession!.addInput(captureDeviceInput!)

        // add output: this class (AVCaptureVideoDataOutputSampleBufferDelegate)
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput!.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA),
        ]
        videoOutput!.alwaysDiscardsLateVideoFrames = true // discard frames when output dispatch queue is blocked
        captureSession!.addOutput(videoOutput!)
        // We want the buffers to be in portrait orientation otherwise they are
        // rotated by 90 degrees. Need to set this _after_ addOutput()!
        videoOutput!.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        
        captureSession!.commitConfiguration()
    }


    public func setDelegate(delegate: VideoSourceDelegate?, queue: DispatchQueue?) {
        if delegate != nil && queue != nil {
            videoOutput?.setSampleBufferDelegate(self, queue: queue)
        } else {
            videoOutput?.setSampleBufferDelegate(nil, queue: nil)
        }
        self.delegate = delegate
    }


    public func start(maxFps: Int) {
        self.maxFps = maxFps
        if let captureSession = captureSession {
            if !captureSession.isRunning {
                captureSession.startRunning()
            }
        }
    }
    

    public func stop() {
        if let captureSession = captureSession {
            if captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
    }


    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp

        if deltaTime >= CMTimeMake(value: 1, timescale: Int32(maxFps)) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

            // process frame
            lastTimestamp = timestamp
            if delegate != nil {
                delegate!.videoCapture(self, pixelBuffer: imageBuffer, timestamp: timestamp)
            }
        }
    }


    public func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        //print("dropped frame")
    }

}
