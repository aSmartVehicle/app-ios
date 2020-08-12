//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  MeasOverallLtcySetupView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI

struct MeasOverallLtcySetupView: View {
    @ObservedObject var worker = OverallLatencyWorker.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @State var numRepetitions: UInt = OverallLatencyWorker.sharedInstance.settings.numRepetitions
    @State var blinkPeriodMs: UInt = OverallLatencyWorker.sharedInstance.settings.blinkPeriodMs
    @State var udpPeriodMs: UInt = OverallLatencyWorker.sharedInstance.settings.udpPeriodMs
    @State var isNoMeasurementStarted: Bool = true


    fileprivate func applySettings() {
        self.worker.settings.numRepetitions = self.numRepetitions
        self.worker.settings.blinkPeriodMs = self.blinkPeriodMs
        self.worker.settings.udpPeriodMs = self.udpPeriodMs
    }

    var body: some View {
        VStack {
            VStack {
                //Text("MEASUREMENT SETUP").bold().padding()
                if (videoProcessor.scaledUiImage != nil) {
                    Image(uiImage: videoProcessor.scaledUiImage!)
                        .resizable()
                }
                HStack {
                    Text("Number of repetitions")
                    Spacer()
                    UIntEntryField(value: $numRepetitions)
                }
                HStack {
                    Text("Blink period (ms)")
                    Spacer()
                    UIntEntryField(value: $blinkPeriodMs)
                }
                HStack {
                    Text("UDP repetition period (ms)")
                    Spacer()
                    UIntEntryField(value: $udpPeriodMs)
                }
                HStack {
                    Text("Threshold (red)")
                    Spacer()
                    Slider(value: $videoProcessor.thresholdRed, in: 0...1)
                }
                HStack {
                    Text("Threshold (green)")
                    Spacer()
                    Slider(value: $videoProcessor.thresholdGreen, in: 0...1)
                }
                HStack {
                    Text("Threshold (blue)")
                    Spacer()
                    Slider(value: $videoProcessor.thresholdBlue, in: 0...1)
                }
            }
            Spacer(minLength: 16)

            VStack {
                //Text("MEASUREMENT EXECUTION").bold().padding()
                HStack {
                    Text("Measurement no (FPS)")
                    Spacer()
                    Text("\(worker.numCurrentMeasurement)/\(worker.settings.numRepetitions) (\(videoProcessor.averageFps.averageFps, specifier: "%.1f"))")
                }
                HStack {
                    Text("Car LED setting")
                    Spacer()
                    Text(worker.carLed ? "On ◉" : "Off ◯")
                }
                HStack {
                    Text("Detected LED")
                    Spacer()
                    Text(videoProcessor.detectedLed ? "On ◉" : "Off ◯")
                }
            }
            Spacer(minLength: 16)


            // Three-State Button Start/Stop/Result
            if (isNoMeasurementStarted) {
                Button(action: {
                    // start measurement
                    self.applySettings()
                    self.worker.startRun()
                    self.isNoMeasurementStarted = false
                }) {
                    Text("Start Measurement")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.green)
                        .cornerRadius(40)
                }
            } else {
                // the measurement was started (and maybe is finished)
                if (worker.isRunning) {
                    Button(action: {
                        // stop measurement
                        self.worker.stopRun()
                    }) {
                        Text("Stop Measurement")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(40)
                    }
                } else {
                    // the measurement was started and has stopped
                    NavigationLink(destination: MeasResultView(result: worker.result)) {
                        Text("Show result")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(40)
                    }
                }
            }
        }
        .padding()
        .navigationBarTitle("Setup", displayMode: .inline)
        .onAppear() {
            self.worker.start()
            self.isNoMeasurementStarted = true
        }.onDisappear() {
            self.worker.stop()
            self.applySettings()
        }
    }
}


struct MeasOverallLtcySetupView_Previews: PreviewProvider {
    static var previews: some View {
        MeasOverallLtcySetupView()
    }
}
