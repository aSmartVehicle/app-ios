//
//  OverallLatencyView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 22.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct MeasureOverallLatencyView: View {
    @ObservedObject var overallLatency = OverallLatencyWorker.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @State var numRepetitions: UInt = 100
    @State var udpPeriodMs: UInt = 500
    @State var thresholdRed: Double = 0.0
    @State var thresholdGreen: Double = 0.0
    @State var thresholdBlue: Double = 0.5


    fileprivate func startMeasurement() {
        result = ""
        overallLatency.start()
    }


    fileprivate func stopMeasurement() {
        overallLatency.stop()
        result = self.overallLatency.getResult()
    }


    var body: some View {
        NavigationView {
            VStack {
                /*
                Text("Overall Latency Measurement")
                    .font(.title)
                    .padding()
                Text("The measurement needs an Embedded Car Controller as a partner for returning UDP packets.")
                    .multilineTextAlignment(.leading)
                    .padding()
                Spacer(minLength: 16)
                */
                VStack {
                    Text("TEST SETUP").bold()
                    HStack {
                        Text("Repetitions")
                        Spacer()
                        UIntEntryField(value: $numRepetitions)
                    }
                    HStack {
                        Text("Period (ms)")
                        Spacer()
                        UIntEntryField(value: $udpPeriodMs)
                    }
                    HStack {
                        Text("Threshold (Red)")
                        Spacer()
                        Slider(value: $thresholdRed, in: 0...1)
                    }
                    HStack {
                        Text("Threshold (Green)")
                        Spacer()
                        Slider(value: $thresholdGreen, in: 0...1)
                    }
                    HStack {
                        Text("Threshold (Blue)")
                        Spacer()
                        Slider(value: $thresholdBlue, in: 0...1)
                    }
                    HStack {
                        Text("Car LED setting")
                        Spacer()
                        Text(overallLatency.carLed ? "On ◉" : "Off ◯")
                    }
                    HStack {
                        Text("Detected LED")
                        Spacer()
                        Text(overallLatency.detectedLed ? "On ◉" : "Off ◯")
                    }

                    if (videoProcessor.scaledUiImage != nil) {
                        Image(uiImage: videoProcessor.scaledUiImage!)
                            .resizable()
                    }
                }
                Spacer(minLength: 16)

                Button(action: {
                    self.overallLatency.isMeasurementRunning ? self.stopMeasurement() : self.startMeasurement()
                }) {
                    if (overallLatency.isMeasurementRunning) {
                        Text("Stop Measurement (\(overallLatency.numCurrentMeasurement)/\(numRepetitions))")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(40)
                    } else {
                        Text("Start Measurement")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(40)
                    }
                }
            }
            .navigationBarTitle("Overall Latency Measurement")
            .onAppear() { OverallLatencyWorker.sharedInstance.start() }
            .onDisappear() { OverallLatencyWorker.sharedInstance.stop() }
        }
        //.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .center)
    }
}


struct OverallLatencyView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureOverallLatencyView()
    }
}
