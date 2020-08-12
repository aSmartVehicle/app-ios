//
//  InferenceView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 31.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct DriveView: View {
    @ObservedObject var worker = DriveWorker.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @ObservedObject var car = Car.sharedInstance
    
    
    func floatStr(_ value: Float?) -> String {
        return (value == nil) ? "?" : String(format: "%4.1f", value!)
    }

    var body: some View {
        VStack {
            AnnotatedImageView()
            Toggle(isOn: $videoProcessor.isSaveTrainingData) {
                Text("Save training data")
            }
            Toggle(isOn: $videoProcessor.isInference) {
                Text("Inference")
            }
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
        }
    .padding()
        .onAppear() {
            self.worker.start()
        }
        .onDisappear() {
            self.worker.stop()
        }
    }
}

struct InferenceView_Previews: PreviewProvider {
    static var previews: some View {
        DriveView()
    }
}
