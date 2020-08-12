//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  OverallLatencyWorker.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import AVFoundation
import CoreVideo

// *******************************************************************

struct OverallLatencySettings: Codable {
    var numRepetitions: UInt = 1000
    var blinkPeriodMs: UInt = 997 //1000
    var udpPeriodMs: UInt = 10
}

// *******************************************************************

class OverallLatencyWorker: ObservableObject {

    struct Measurement: Codable {
        var t_car_led_switched: UInt64 = 0
        var t_videoframe: UInt64 = 0
        var t_processing_start: UInt64 = 0
        var t_processing_end: UInt64 = 0
        var dt_camera_ms: Double = 0
        var dt_overall_ms: Double = 0
        var dt_processing_ms: Double = 0
        var dt_preprocessing_ms: Double = 0
        var dt_save_ms: Double = 0
        var dt_inference_ms: Double = 0
        var dt_detect_ms: Double = 0
        var dt_display_ms: Double = 0

        var car_led_state: UInt64 = 0
        var car_led_detected: UInt64 = 0
        var new_detection: UInt64 = 0
    }

    static let sharedInstance = OverallLatencyWorker()
    var settings = OverallLatencySettings()
    private let car: Car
    private let videoProcessor: VideoProcessor

    private let workerQueue: DispatchQueue
    private var blinkTimer: DispatchSourceTimer?
    private var udpTimer: DispatchSourceTimer?
    private var ledDetectionObservationToken: ObservationToken? = nil
    private var measurements: [Measurement] = []
    private var isCarLedAlreadyDetected = false
    private var carLedSwitchTimeNanos: UInt64 = 0


    // ***** UI-observable properties *****

    private(set) var isRunning: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var numCurrentMeasurement: Int = 0 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    private(set) var carLed: Bool = false {
        willSet {
            self.carLedSwitchTimeNanos = getTimeNanos()
            self.isCarLedAlreadyDetected = false
            let message = MessageToCar(led: !carLed ? 1 : 0) // negation because of willSet
            self.car.send(data: message)
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var result: String {
        get {
            var s = ""
            let mirror = Mirror(reflecting: measurements[0])
            for field in mirror.children {
                s += field.label! + "\t"
            }
            s += "\n"
            for measurement in measurements {
                let mirror = Mirror(reflecting: measurement)
                for field in mirror.children {
                    s += "\(field.value)\t"
                }
                s += "\n"
            }
            return s
        }
    }


    // ***** Lifecycle: init and start/stop *****

    private init(car: Car = Car.sharedInstance, videoProcessor: VideoProcessor = VideoProcessor.sharedInstance) {
        self.car = car
        self.videoProcessor = videoProcessor
        workerQueue = DispatchQueue(label: "LatencyMeasurementQueue", qos: .default)
    }

    public func start() {
        print("Starting OverallLatencyWorker")
        isRunning = false
        car.start(autoUdpTransmission: false)
        videoProcessor.start(isSaveTrainingData: false, isInference: true, isDetectColor: true)
        ledDetectionObservationToken = videoProcessor.observeLedDetection { videoProcessor, detectedLed, timing in
            self.workerQueue.async {
                self.onLedDetection(detectedLed: detectedLed, timing: timing)
            }
        }
        startBlinkTimer()
        startUdpTimer()
    }

    public func stop() {
        stopRun()
        print("Stopping OverallLatencyWorker")
        stopTimer(timer: &blinkTimer)
        carLed = false
        stopTimer(timer: &udpTimer)
        ledDetectionObservationToken?.cancel()
        videoProcessor.stop()
        let message = MessageToCar(led: 0)
        workerQueue.asyncAfter(deadline: .now()+0.01, execute: { self.car.send(data: message) })
        workerQueue.asyncAfter(deadline: .now()+0.02, execute: {
            self.car.send(data: message)
            self.car.stop()
        })
    }

    public func startRun() {
        print("Starting measurement settings=\(settings)")
        // start with defined timing
        isCarLedAlreadyDetected = false
        stopTimer(timer: &blinkTimer)
        startBlinkTimer()
        
        // initialize measurement
        numCurrentMeasurement = 0
        measurements = Array(repeating: Measurement(), count: Int(settings.numRepetitions))
        isRunning = true
    }

    public func stopRun() {
        print("Stopping measurement")
        isRunning = false
    }

    
    // ***** Timer *****

    private func startBlinkTimer() {
        if blinkTimer != nil {
            print("Error: blinkTimer exists")
        } else {
            carLed = false
            let interval = Double(settings.blinkPeriodMs) / 1000.0
            blinkTimer = DispatchSource.makeTimerSource() //flags: [], queue: workerQueue)
            blinkTimer?.schedule(deadline: .now() + interval, repeating: interval)
            blinkTimer?.setEventHandler(handler: { [weak self] in
                self?.onBlinkTimer()
            })
            blinkTimer?.resume()
        }
    }

    private func startUdpTimer() {
        if udpTimer != nil {
            print("Error: udpTimer exists")
        } else {
            let interval = Double(settings.udpPeriodMs) / 1000.0
            udpTimer = DispatchSource.makeTimerSource() //flags: [], queue: workerQueue)
            udpTimer?.schedule(deadline: .now() + interval, repeating: interval)
            udpTimer?.setEventHandler(handler: { [weak self] in
                self?.onUdpTimer()
            })
            udpTimer?.resume()
        }
    }

    private func stopTimer(timer: inout DispatchSourceTimer?) {
        if timer != nil {
            timer?.setEventHandler {}
            timer?.cancel()
            timer = nil
        }
    }

    private func onBlinkTimer() {
        carLed = !carLed
    }

    private func onUdpTimer() {
        let message = MessageToCar(led: carLed ? 1 : 0)
        self.car.send(data: message)
    }
    
    
    // ***** VideoProcessor callback *****
    
    func onLedDetection(detectedLed: Bool, timing: VideoProcessingTiming) {

        let newDetectionFlag: Bool = !isCarLedAlreadyDetected && (carLed == detectedLed)
        let t_led = Double(carLedSwitchTimeNanos) / 1e6
        if (isRunning && newDetectionFlag) {
            // save the measurement
            let dt_processing = Double(timing.t_processing_end - timing.t_processing_start) / 1000 / 1000
            let dt_preprocessing = Double(timing.t_preprocessing_end - timing.t_preprocessing_start) / 1000 / 1000
            let dt_save = Double(timing.t_save_end - timing.t_save_start) / 1000 / 1000
            let dt_inference = Double(timing.t_inference_end - timing.t_inference_start) / 1000 / 1000
            let dt_detect = Double(timing.t_detect_end - timing.t_detect_start) / 1000 / 1000
            let dt_display = Double(timing.t_display_end - timing.t_display_start) / 1000 / 1000
            let dt_overall = Double(timing.t_processing_end) / 1e6 - t_led
            let dt_camera = Double(timing.t_processing_start) / 1e6 - t_led
            let measurement = Measurement(t_car_led_switched: carLedSwitchTimeNanos, t_videoframe: timing.t_videoframe, t_processing_start: timing.t_processing_start, t_processing_end: timing.t_processing_end, dt_camera_ms: dt_camera, dt_overall_ms: dt_overall, dt_processing_ms: dt_processing, dt_preprocessing_ms: dt_preprocessing, dt_save_ms: dt_save, dt_inference_ms: dt_inference, dt_detect_ms: dt_detect, dt_display_ms: dt_display, car_led_state: (carLed ? 1 : 0), car_led_detected: (detectedLed ? 1 : 0), new_detection: (newDetectionFlag ? 1 : 0))

            if numCurrentMeasurement < measurements.count {
                measurements[numCurrentMeasurement] = measurement
                print("measurements[\(numCurrentMeasurement)]=\(measurements[numCurrentMeasurement])")
                numCurrentMeasurement += 1
            } else {
                print("\(measurement)")
                isRunning = false
            }

            if newDetectionFlag {
                isCarLedAlreadyDetected = true
            }
        }
    }

}
