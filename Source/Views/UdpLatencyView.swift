//
//  UdpLatencyView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 22.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI
import Combine


struct MeasureUdpLatencyView: View {
    let udpLatency = UdpLatencyWorker.sharedInstance

    @State var isMeasurementRunning: Bool = false
    @State var result: String = ""
    @State var status: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()


    fileprivate func updateStatus() {
        status = "Sent \(udpLatency.numSent)/\(udpLatency.settings.numRepetitions), Rcv \(udpLatency.numReceived)"
    }


    fileprivate func startMeasurement() {
        status = ""
        result = ""
        udpLatency.start()
    }
    

    fileprivate func stopMeasurement() {
        udpLatency.stop()
        result = self.udpLatency.getResult()
    }


    var body: some View {
        VStack {
            Text("UDP Latency Measurement")
                .font(.title)
                .padding()
            Text("The measurement needs an Embedded Car Controller as a partner for returning UDP packets.")
                .multilineTextAlignment(.leading)
                .padding()
            Spacer(minLength: 16)

            VStack {
                Text("TEST SETUP").bold()
                HStack {
                    Text("Repetitions")
                    Spacer()
                    Text("\(udpLatency.settings.numRepetitions)")
                }
                HStack {
                    Text("Period (ms)")
                    Spacer()
                    Text("\(udpLatency.settings.periodMs)")
                }
            }
            Spacer(minLength: 16)

            Button(action: {
                self.isMeasurementRunning ? self.stopMeasurement() : self.startMeasurement()
                self.isMeasurementRunning = !self.isMeasurementRunning
            }) {
                if (isMeasurementRunning) {
                    Text("Stop Measurement (\(status))")
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
            Spacer(minLength: 16)

            VStack {
                HStack {
                    Text("TEST RESULT").bold()
                    Button(action: {
                        print("Copy Result to Clipboard:\n\(self.result)")
                        UIPasteboard.general.string = self.result
                    }) {
                        Text("(Copy)")
                    }
                }
                ScrollView {
                    TextField("Result", text: $result)
                }
            }
            Spacer()
        }
        .padding()
        .onReceive(timer, perform: { input in self.updateStatus() })
        .onDisappear() { self.stopMeasurement() }
    }
}

struct UdpLatencyView_Previews: PreviewProvider {
    static var previews: some View {
        MeasureUdpLatencyView()
    }
}
