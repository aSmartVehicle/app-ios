//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  Helper.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import Foundation
import CoreLocation
import SystemConfiguration.CaptiveNetwork
import AVFoundation


// ***** Timing *****

public func getTimeNanos() -> UInt64 {
    var info = mach_timebase_info()
    guard mach_timebase_info(&info) == KERN_SUCCESS else { return 0 }
    let currentTime = mach_absolute_time()
    let nanos = currentTime * UInt64(info.numer) / UInt64(info.denom)
    return nanos
}

// ***** FPS *****

class FpsAveraging: ObservableObject {
    var averageFps: Double = 0.0 {
        willSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }

    // all internal times are in nanoseconds
    private var lastTimestamp: UInt64 = getTimeNanos()
    private let averagingIntervalDuration: UInt64 = UInt64(1*1e9)
    private var averagingIntervalStartTime: UInt64 = getTimeNanos()
    private var averagingIntervalCounter = 0

    init() {
        reset()
    }

    public func reset() {
        averageFps = 0
        averagingIntervalStartTime = getTimeNanos()
        averagingIntervalCounter = 0
    }

    public func update() {
        let timestamp = getTimeNanos()
        let duration = timestamp - averagingIntervalStartTime

        averagingIntervalCounter += 1
        if duration >= averagingIntervalDuration {
            // calculate a new average and start a new measurement
            averageFps = Double(averagingIntervalCounter) / (Double(duration) * 1e-9)
            averagingIntervalStartTime = timestamp
            averagingIntervalCounter = 0
        }
    }
}


// ***** Observer *****
// Source: Swift by Sundell, https://www.swiftbysundell.com/articles/observers-in-swift-part-2/

class ObservationToken {
    private let cancellationClosure: () -> Void

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    func cancel() {
        cancellationClosure()
    }
}


// ***** WiFi *****

class WifiManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let sharedInstance = WifiManager()
    var lm = CLLocationManager()
    @Published var authStatus: CLAuthorizationStatus = .notDetermined
    @Published var WifiSsid: String = ""

    private override init() {
        super.init()
        lm.delegate = self
        lm.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authStatus = status
        print("Location access change authStatus=\(authStatus)")
    }

    func requestLocationAccess() {
        // check location access
        if authStatus == .notDetermined {
            lm.requestWhenInUseAuthorization()
        }
    }
}

func getWiFiSsid() -> String? {
    var ssid: String?
    if let interfaces = CNCopySupportedInterfaces() as NSArray? {
        for interface in interfaces {
            if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                break
            }
        }
    }
    return ssid
}
