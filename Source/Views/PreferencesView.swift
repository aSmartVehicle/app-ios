//
//  SettingsView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 22.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    let car = Car.sharedInstance
    var sshSettings = Datastore.sharedInstance.settings

    // CarSettings
    @State var localPort: UInt = Car.sharedInstance.settings.localPort
    @State var remoteAddress: String = Car.sharedInstance.settings.remoteAddress
    @State var remotePort: UInt = Car.sharedInstance.settings.remotePort
    @State var isBroadcast: Bool = Car.sharedInstance.settings.isBroadcast

    // VideoProcessorSettings
    @State var maxFps: Int = VideoProcessor.sharedInstance.settings.maxFps
    @State var scaledWidth: Int = VideoProcessor.sharedInstance.settings.scaledWidth
    @State var scaledHeight: Int = VideoProcessor.sharedInstance.settings.scaledHeight
    @State var croppingRect: CGRect = VideoProcessor.sharedInstance.settings.croppingRect

    // UdpLatencySettings
    @State var numRepetitions: UInt = UdpLatencyWorker.sharedInstance.settings.numRepetitions
    @State var periodMs: UInt = UdpLatencyWorker.sharedInstance.settings.periodMs
    
    // OverallLatencySettings

    // Demo
    @State var username: String = ""
    @State private var previewIndex = 0
    var previewOptions = ["Always", "When Unlocked", "Never"]


    func applySettings() {
        let car = Car.sharedInstance
        let videoProcessor = VideoProcessor.sharedInstance
        let udpLatencyWorker = UdpLatencyWorker.sharedInstance
        //var overallLatencySettings = OverallLatencyWorker.sharedInstance

        // CarSettings
        car.settings.localPort = localPort
        car.settings.remoteAddress = remoteAddress
        car.settings.remotePort = remotePort
        car.settings.isBroadcast = isBroadcast

        // VideoProcessorSettings
        videoProcessor.settings.maxFps = maxFps
        videoProcessor.settings.scaledWidth = scaledWidth
        videoProcessor.settings.scaledHeight = scaledHeight
        videoProcessor.settings.croppingRect = croppingRect

        // UdpLatencySettings
        udpLatencyWorker.settings.numRepetitions = numRepetitions
        udpLatencyWorker.settings.periodMs = periodMs

        // OverallLatencySettings
    }
    

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("EMBEDDED CAR CONTROLLER")) {
                    HStack {
                        Text("Remote IP Address")
                        Spacer()
                        TextField("Remote Address", text: $remoteAddress)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Remote Port")
                        Spacer()
                        UIntEntryField(value: $remotePort)
                    }
                    HStack {
                        Text("Local Port")
                        Spacer()
                        UIntEntryField(value: $localPort)
                    }
                    Toggle(isOn: $isBroadcast) {
                        Text("Broadcast")
                    }
                    /*
                    HStack {
                        Text("Period (UDP transmission, ms)")
                        Spacer()
                        UIntEntryField(value: $car.settings.timerPeriodMs)
                    }
                    */
                }

                Section(header: Text("VIDEO PROCESSOR")) {
                    HStack {
                        Text("Max FPS")
                        Spacer()
                        IntEntryField(value: $maxFps)
                    }
                    HStack {
                        Text("Scaled Image Width")
                        Spacer()
                        IntEntryField(value: $scaledWidth)
                    }
                    HStack {
                        Text("Scaled Image Height")
                        Spacer()
                        IntEntryField(value: $scaledHeight)
                    }
                    // croppingRect
                }

                Section(header: Text("SSH FILE TRANSFER")) {
                    Text("TODO")
                    /*
                    HStack {
                        Text("Remote Host")
                        Spacer()
                        TextField("Remote Host", text: $)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Remote Username")
                        Spacer()
                        IntEntryField(value: $maxFps)
                    }
                    HStack {
                        Text("Scaled Image Width")
                        Spacer()
                        IntEntryField(value: $scaledWidth)
                    }
                    HStack {
                        Text("Scaled Image Height")
                        Spacer()
                        IntEntryField(value: $scaledHeight)
                    }
                    // croppingRect
                     */
                }

                Section(header: Text("UDP TRANSMISSION LATENCY")) {
                    HStack {
                        Text("Number of Repetitions")
                        Spacer()
                        UIntEntryField(value: $numRepetitions)
                    }
                    HStack {
                        Text("Period (ms)")
                        Spacer()
                        UIntEntryField(value: $periodMs)
                    }
                }

                Section(header: Text("DEMO")) {
                    TextField("Username", text: $username)
                    Picker(selection: $previewIndex, label: Text("Show Previews")) {
                        ForEach(0 ..< previewOptions.count) {
                            Text(self.previewOptions[$0])
                        }
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("2.2.1")
                    }
                    Button(action: {
                        print("Perform an action here...")
                    }) {
                        Text("Reset All Settings")
                    }
                }

            }
            .navigationBarTitle("Settings")
        }
        .onDisappear() {
            self.applySettings()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
