//
//  TrainingView.swift
//  ASV
//
//  Created by Claus Fühner on 06.08.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct TrainingView: View {
    @ObservedObject var worker = DriveWorker.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @ObservedObject var car = Car.sharedInstance
    @ObservedObject var controller = Controller.sharedInstance
    @ObservedObject var datastore = Datastore.sharedInstance

    @State var isRecording: Bool = false


    func floatStr(_ value: Float?) -> String {
        return (value == nil) ? "?" : String(format: "%4.1f", value!)
    }

    var body: some View {
        NavigationView {
            VStack {
                AnnotatedImageView()
                Spacer()
                Section {
                    HStack {
                        Text("Manual Steering/Throttle")
                        Spacer()
                        Text("\(floatStr(car.manualSteering)) / \(floatStr(car.manualThrottle))")
                    }
                    HStack {
                        Text("Mode")
                        Spacer()
                        Text("\(car.mode.rawValue)")

                    }
                    HStack {
                        Text("Training datasets")
                        Spacer()
                        Text("\(datastore.numberOfTrainingDatasets)")

                    }
                }
                Spacer()
                NavigationLink(destination: TrainingDataManagementView()) {
                    Text("Manage Training Data")
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
                Spacer()
                if (self.videoProcessor.isSaveTrainingData) {
                    // stop stop recording button
                    Button(action: {
                        self.videoProcessor.isSaveTrainingData = false
                    }) {
                        Text("Stop recording")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(40)
                    }
                } else {
                    // show start recording button
                    Button(action: {
                        self.videoProcessor.isSaveTrainingData = true
                    }) {
                        Text("Start recording")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(self.videoProcessor.isSaveTrainingData == true ? Color.gray : Color.green)
                            .cornerRadius(40)
                    }
                }
            }
            .navigationBarTitle("Training", displayMode: .inline)
            .padding()
        }
        .onAppear() {
            self.worker.start(isTraining: true)
        }
        .onDisappear() {
            self.worker.stop()
        }
    }
}

struct TrainingView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingView()
    }
}
