//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  UdpLatencyWorker.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import AVFoundation
import CocoaAsyncSocket

// *******************************************************************

struct UdpLatencySettings: Codable {
    var numRepetitions: UInt = 1000
    var periodMs: UInt = 100
}

// *******************************************************************

class UdpLatencyWorker: ObservableObject {

    struct Measurement: Codable {
        var t1: UInt64 = 0
        var t2: UInt64 = 0
        var t3: UInt64 = 0
        var t4: UInt64 = 0

        var dt_rtt2_ms: Double = 0
        var dt_esp32_ms: Double = 0
        var dt_overall_ms: Double = 0
    }

    static let sharedInstance = UdpLatencyWorker()
    var settings = UdpLatencySettings()
    private let car: Car

    private let workerQueue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var newDataFromCarObservationToken: ObservationToken? = nil
    private var measurements: [Measurement] = []


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
    private(set) var numReceived: Int = 0 {
        willSet {
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

    private init(car: Car = Car.sharedInstance) {
        self.car = car
        workerQueue = DispatchQueue(label: "UdpLatencyMeasurementQueue", qos: .default)
    }
    
    
    public func start() {
        print("Starting UdpLatencyWorker")
        isRunning = false
        // nothing to do, just to keep a common interface
    }

    public func stop() {
        stopRun()
        print("Stopping UdpLatencyWorker")
        // nothing to do, just to keep a common interface
    }

    public func startRun() {
        print("Starting measurement with settings=\(settings)")

        // initialize measurement
        self.numCurrentMeasurement = 0
        self.numReceived = 0
        self.measurements = Array(repeating: Measurement(), count: Int(settings.numRepetitions))
        isRunning = true

        // setup UDP reception
        car.start(autoUdpTransmission: false)
        newDataFromCarObservationToken = car.observeNewDataFromCar { car, timestamp, message in
            self.workerQueue.async {
                self.newMessageFromCar(car, timestamp: timestamp, message: message)
            }
        }

        // initialize timer
        if timer != nil {
            print("Error: Timer exists, there's already a measurement running")
        } else {
            let interval = Double(settings.periodMs) / 1000.0
            timer = DispatchSource.makeTimerSource() //flags: [], queue: workerQueue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler(handler: { [weak self] in
                self?.timerEvent()
            })
            timer?.resume()
        }
    }

    public func stopSending() {
        print("Stopping sending data")
        if timer != nil {
            timer?.setEventHandler {}
            timer?.cancel()
            timer = nil
        }
    }

    public func stopRun() {
        print("Stopping measurement")
        stopSending()
        newDataFromCarObservationToken?.cancel()
        car.stop()
        isRunning = false
    }


    // ***** send data to car *****

    private func timerEvent() {
        if (numCurrentMeasurement < settings.numRepetitions) {
            let timestamp = getTimeNanos()
            let messageToCar = MessageToCar(t1: timestamp)
            measurements[numCurrentMeasurement].t1 = timestamp
            car.send(data: messageToCar)
            measurements[numCurrentMeasurement].t2 = 0
            measurements[numCurrentMeasurement].t3 = 0
            measurements[numCurrentMeasurement].t4 = 0
            numCurrentMeasurement += 1
        } else {
            stopSending()
        }
    }


    // ***** receive data from car *****

    private func newMessageFromCar(_ car: Car, timestamp: UInt64, message: MessageFromCar) {
        guard let t1 = message.t1, let t2 = message.t2, let t3 = message.t3 else {
            print("Error in newMessageFromCar decoding message=\(message)")
            return
        }
        let t4 = timestamp
        if let i = measurements.firstIndex(where: { $0.t1 == t1 } ) {
            measurements[i].t2 = t2
            measurements[i].t3 = t3
            measurements[i].t4 = timestamp
            measurements[i].dt_rtt2_ms = Double( (t4 - t1) - (t3 - t2) ) / 2 / 1e6
            measurements[i].dt_esp32_ms = Double( t3 - t2 ) / 1e6
            measurements[i].dt_overall_ms = Double( t4 - t1 ) / 1e6
            print("latencyMeasurements[\(i)]=\(measurements[i])")
            self.numReceived += 1
        } else {
            print("Error t1=\(String(describing: message.t1)) not found:\n\(message)")
        }
    }

}
