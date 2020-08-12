//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  InferenceWorker.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import AVFoundation
import CoreVideo

// *******************************************************************

struct DriveSettings: Codable {
}

// *******************************************************************

class DriveWorker: ObservableObject {
    static let sharedInstance = DriveWorker()
    var settings = DriveSettings()
    private let car: Car
    private let videoProcessor: VideoProcessor


    // ***** Lifecycle: init and start/stop *****

    private init(car: Car = Car.sharedInstance, videoProcessor: VideoProcessor = VideoProcessor.sharedInstance) {
        self.car = car
        self.videoProcessor = videoProcessor
    }

    public func start(isTraining: Bool) {
        print("Starting Drive with settings=\(settings)")
        videoProcessor.start(isSaveTrainingData: false, isInference: !isTraining, isDetectColor: false)
        car.start(autoUdpTransmission: true)
    }

    public func stop() {
        print("Stopping DriverWorker")
        car.stop()
        videoProcessor.stop()
    }
}
