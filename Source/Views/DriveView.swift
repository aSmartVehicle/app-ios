//
//  InferenceView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 31.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct InferenceView: View {
    @ObservedObject var worker = DriveWorker.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @ObservedObject var car = Car.sharedInstance
    @ObservedObject var controller = Controller.sharedInstance


    func floatStr(_ value: Float?) -> String {
        return (value == nil) ? "?" : String(format: "%4.1f", value!)
    }

    var body: some View {
        NavigationView {
            VStack {
                AnnotatedImageView()
                if (videoProcessor.croppedUiImage != nil) {
                    Image(uiImage: videoProcessor.croppedUiImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                HistogramView(values: videoProcessor.steeringCategorical.array, scaleMax: 1.0, indexSelected: videoProcessor.steeringCategorical.index)
                HStack {
                    Text("Manual Steering/Throttle")
                    Spacer()
                    Text("\(floatStr(car.manualSteering)) / \(floatStr(car.manualThrottle))")
                }
                HStack {
                    Text("Auto Steering/Throttle")
                    Spacer()
                    Text("\(floatStr(car.autoSteering)) / \(floatStr(car.autoThrottle))")
                }
                HStack {
                    Text("Mode")
                    Spacer()
                    Text("\(car.mode.rawValue)")

                }
                Spacer()
                NavigationLink(destination: NetworkManagementView()) {
                    Text("Manage Neural Network")
                }
                Spacer()
                // Mode selection
                HStack {
                    Button(action: {
                        self.controller.mode = .stop
                    }) {
                        Text("Stop")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(40)
                    }.disabled( self.controller.mode == .stop )
                    Button(action: {
                        self.controller.mode = .manual
                    }) {
                        Text("Manual")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(40)
                    }.disabled(self.controller.mode == .manual)
                    Button(action: {
                        self.controller.mode = .auto
                    }) {
                        Text("Auto")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(40)
                    }.disabled(self.controller.mode == .auto)
                }
            }
            .navigationBarTitle("Inference", displayMode: .inline)
            .padding()
        }
        .onAppear() {
            self.worker.start(isTraining: false)
        }
        .onDisappear() {
            self.worker.stop()
        }
    }
}

struct InferenceView_Previews: PreviewProvider {
    static var previews: some View {
        InferenceView()
    }
}
