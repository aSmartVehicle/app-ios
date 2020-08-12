//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  Car.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import AVFoundation
import CocoaAsyncSocket

// *******************************************************************

enum Mode: String, Codable {
    case stop, manual, auto
}

// *******************************************************************

struct MessageFromCar : Codable {
    var t1: UInt64?
    var t2: UInt64?
    var t3: UInt64?
    var t4: UInt64?
    var battery: Double?
}

// *******************************************************************

struct MessageToCar : Codable {
    var t1: UInt64?
    var t2: UInt64?
    var t3: UInt64?
    var t4: UInt64?
    var led: Int?
    var steering: Float?
    var throttle: Float?
    var mode: Mode?
}

// *******************************************************************

struct CarSettings {
    var localPort: UInt = 10000
    var remoteAddress: String = "192.168.4.1" // "192.168.178.26" // "192.168.4.1"
    var remotePort: UInt = 10001
    var isBroadcast: Bool = false
    var timerPeriodMs: UInt = 10
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

class Car: NSObject, GCDAsyncUdpSocketDelegate, ObservableObject {
    static let sharedInstance = Car()
    var settings = CarSettings()
    let controller: Controller

    private let carQueue: DispatchQueue
    private var timer: DispatchSourceTimer?
    private var udpSocket: GCDAsyncUdpSocket?
    private var newDataFromCarObservations = [UUID : (Car, UInt64, MessageFromCar) -> Void]()
    private var autoUdpTransmission: Bool = false
    private var lastReceiveTimestamp: UInt64? = nil


    // ***** UI-observable properties *****

    private(set) var batteryVoltage: Float? = 0 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private(set) var manualSteering: Float? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private(set) var manualThrottle: Float? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private(set) var autoSteering: Float? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private(set) var autoThrottle: Float? = nil {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    private(set) var mode: Mode = .stop {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }


    // ***** Lifecycle: init, delegation and start/stop *****

     init(controller: Controller = Controller.sharedInstance) {
        self.controller = controller
        self.carQueue = DispatchQueue(label: "CarQueue", qos: .default)
        super.init()
    }

    public func start(autoUdpTransmission: Bool) {
        print("Starting Car(autoUdpTransmission: \(autoUdpTransmission) with settings=\(settings)")
        self.autoUdpTransmission = autoUdpTransmission

        // setup UDP reception
        let sock = GCDAsyncUdpSocket(delegate: self, delegateQueue: carQueue)
        do {
            sock.setIPv4Enabled(true)
            sock.setIPv6Enabled(false)
            try sock.bind(toPort: UInt16(settings.localPort))
            try sock.enableBroadcast(settings.isBroadcast)
            try sock.beginReceiving()
            self.udpSocket = sock
        } catch let err as NSError {
            print("Error initializing socket for listening: \(err.localizedDescription)")
        }

        // setup timer
        if timer != nil {
            print("Error: timer already exists")
        } else {
            let interval = Double(settings.timerPeriodMs) / 1000.0
            timer = DispatchSource.makeTimerSource() //flags: [], queue: workerQueue)
            timer?.schedule(deadline: .now() + interval, repeating: interval)
            timer?.setEventHandler(handler: { [weak self] in
                self?.onTimer()
            })
            timer?.resume()
        }
    }

    public func stop() {
        print("Stopping car")
        autoUdpTransmission = false
        if timer != nil {
            timer?.setEventHandler {}
            timer?.cancel()
            timer = nil
        }
        if udpSocket != nil {
            udpSocket?.close()
            udpSocket = nil
        }
    }


    
    // ***** Helper *****

    @discardableResult
    func observeNewDataFromCar(using closure: @escaping (Car, UInt64, MessageFromCar) -> Void) -> ObservationToken {
        let id = newDataFromCarObservations.insert(closure)

        return ObservationToken { [weak self] in
            self?.newDataFromCarObservations.removeValue(forKey: id)
        }
    }

    func set(autoSteering: Float?, autoThrottle: Float?) {
        self.autoSteering = autoSteering
        self.autoThrottle = autoThrottle
        sendControlMessageToCar()
    }

    private func sendControlMessageToCar() {
        switch (mode) {
        case .manual:
            send( data: MessageToCar(steering: manualSteering, throttle: manualThrottle, mode: mode) )
        case .auto:
            send( data: MessageToCar(steering: autoSteering, throttle: autoThrottle, mode: mode) )
        default:
            send( data: MessageToCar(steering: 0, throttle: 0, mode: .stop) )
        }
    }


    // ***** Timer *****

    private func onTimer() {
        // poll the controller
        controller.poll()
        self.manualSteering = controller.steering
        self.manualThrottle = controller.throttle
        
        var mode: Mode = .stop
        switch (controller.mode) {
        case .stop:
            mode = .stop
        case .manual:
            mode = .manual
        case .auto:
            mode = (self.autoSteering != nil && self.autoThrottle != nil) ? .auto : .stop
        }
        self.mode = mode
        //print("car=\(mode)")

        // UDP transmission
        if autoUdpTransmission {
            sendControlMessageToCar()
        }
    }

    // ***** send data via UDP *****************************************************

    private func sendDataUdp(data: Data) {
        if let udpSocket = self.udpSocket {
            udpSocket.send(data, toHost: settings.remoteAddress, port: UInt16(settings.remotePort), withTimeout: -1, tag: 0)
        } else {
            // print("Error: Data not sent (udpSocket=nil)")
        }
    }

    public func send(data: MessageToCar) {
        let encoder = JSONEncoder()
        if let jsonData = try? encoder.encode(data) {
            //print("Send: \(jsonData)")
            sendDataUdp(data: jsonData)
        } else {
            print("Error: Coundn't encode JSON in send")
        }
    }


    // ***** callbacks for UDP library *********************************************

    // called to confirm sending UDP messages
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        // do nothing: we're not interested in confirmations when sending data
        //print("ok udpSocket didSendDataWithTag", tag)
    }


    // called on error
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("error didNotSendDataWidthTag=\(tag) dueToError=\(error.debugDescription)")
    }

    // called on receiving data
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        //print("Received ", String(data: data, encoding: String.Encoding.utf8))
        // decode received JSON data
        let timestamp = getTimeNanos()
        let decoder = JSONDecoder()

        // call delegate for message processing
        if let message = try? decoder.decode(MessageFromCar.self, from: data) {
            lastReceiveTimestamp = timestamp
            newDataFromCarObservations.values.forEach { closure in
                closure(self, timestamp, message)
            }
        } else {
            print("Error: Unable to decode JSON message received:\n\(data)")
        }
    }

}
