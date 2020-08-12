//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  MeasUdpLtcySetupView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI

struct MeasUdpLtcySetupView: View {
    @ObservedObject var worker = UdpLatencyWorker.sharedInstance
    @State var numRepetitions: UInt = UdpLatencyWorker.sharedInstance.settings.numRepetitions
    @State var periodMs: UInt = UdpLatencyWorker.sharedInstance.settings.periodMs
    @State var isNoMeasurementStarted: Bool = true

    
    fileprivate func applySettings() {
        UdpLatencyWorker.sharedInstance.settings.numRepetitions = self.numRepetitions
        UdpLatencyWorker.sharedInstance.settings.periodMs = self.periodMs
    }

    var body: some View {
        VStack {
            VStack {
                Text("MEASUREMENT SETUP").bold().padding()
                HStack {
                    Text("Number of repetitions")
                    Spacer()
                    UIntEntryField(value: $numRepetitions)
                }
                HStack {
                    Text("UDP transmit period (ms)")
                    Spacer()
                    UIntEntryField(value: $periodMs)
                }
            }
            Spacer(minLength: 16)

            VStack {
                Text("MEASUREMENT EXECUTION").bold().padding()
                HStack {
                    Text("Sent #")
                    Spacer()
                    Text("\(worker.numCurrentMeasurement)/\(worker.settings.numRepetitions)")
                }
                HStack {
                    Text("Received #")
                    Spacer()
                    Text("\(worker.numReceived)")
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
        .navigationBarTitle("Measurement", displayMode: .inline)
        .onAppear() {
            self.worker.start()
            self.isNoMeasurementStarted = true
        }.onDisappear() {
            self.worker.stop()
            self.applySettings()
        }
    }
}


struct MeasUdpLtcySetupView_Previews: PreviewProvider {
    static var previews: some View {
        MeasUdpLtcySetupView()
    }
}
