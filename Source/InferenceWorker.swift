//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  InferenceWorker.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import AVFoundation
import CoreVideo


class DriveWorker: ObservableObject {

    struct InferenceSettings: Codable {
        var udpPeriodMs: UInt = 10
    }


    static let sharedInstance = DriveWorker()
    private let car = Car.sharedInstance
    private let videoProcessor = VideoProcessor.sharedInstance
    var settings = InferenceSettings()
    let workerQueue: DispatchQueue
    private var udpTimer: DispatchSourceTimer?

    var isRunning: Bool = false {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }


    private init(controller: Controller = Controller.sharedInstance) {
        workerQueue = DispatchQueue(label: "InferenceQueue", qos: .default)
    }

    public func start() {
        print("Starting InferenceWorker with settings=\(settings)")
        car.start(autoUdpTransmission: true)
        //car.setDelegate(delegate: self, queue: workerQueue)  we're not interested in messages from the car
        videoProcessor.start(isSaveTrainingData: false, isInference: true, isDetectColor: false)
    }

    public func stop() {
        print("Stopping InferenceWorker")
        stopTimer(timer: &udpTimer)
        videoProcessor.stop()
        /*
        let message = MessageToCar(led: 0)
        workerQueue.asyncAfter(deadline: .now()+0.01, execute: { self.car.send(data: message) })
        workerQueue.asyncAfter(deadline: .now()+0.02, execute: {
            self.car.send(data: message)
            self.car.stop()
            self.car.setDelegate(delegate: nil, queue: nil)
        })
        */
    }

    
    // ***** Timer *****

    private func stopTimer(timer: inout DispatchSourceTimer?) {
        if timer != nil {
            timer?.setEventHandler {}
            timer?.cancel()
            timer = nil
        }
    }

    private func onUdpTimer() {
        //let message = MessageToCar(led: carLed ? 1 : 0)
        //self.car.send(data: message)
    }


    // ***** VideoProcessor callback *****


}
