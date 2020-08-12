//
//  NetworkDownloadView.swift
//  ASV
//
//  Created by Claus Fühner on 06.08.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct NetworkManagementView: View {
    @ObservedObject var datastore = Datastore.sharedInstance
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @State var isOperationPending: Bool = false
    @State var allowLowPrecisionAccumulationOnGPU: Bool = false

    var body: some View {
        VStack {
            Text("Download a trained CoreML model from the SSH server. The model's input is a 160x50 image (or whatever size after cropping) in 32BGRA format. The output is an array of 15 Double values containing the probabilities for the respective steering angles.")
                .multilineTextAlignment(.leading)
            Spacer(minLength: 16)
            Section(header: Text("SSH SERVER SETTINGS")) {
                HStack {
                    Text("Remote IP Address")
                    Spacer()
                    TextField("Remote Host", text: $datastore.settings.remoteHost)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Remote Username")
                    Spacer()
                    TextField("Remote Username", text: $datastore.settings.remoteUsername)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Remote Password")
                    Spacer()
                    SecureField("Remote Password", text: $datastore.settings.remotePassword)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Remote Directory")
                    Spacer()
                    TextField("Remote Directory", text: $datastore.settings.remoteDirectory)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Model name (.mlmodel)")
                    Spacer()
                    TextField("Model name (.mlmodel)", text: $datastore.settings.remoteMlModelName)
                        .multilineTextAlignment(.trailing)
                }
            }
            Section(header: Text("CURRENT MODEL")) {
                Toggle(isOn: $allowLowPrecisionAccumulationOnGPU) {
                    Text("Allow low precision accumulation on GPU")
                }.disabled(true)
            }
            Spacer()
            if (self.isOperationPending) {
                Section(header: Text("PROGRESS")) {
                    Text("Downloading \(datastore.settings.remoteMlModelName)")
                }.padding()
                Spacer()
            }
            if (!self.isOperationPending) {
                Section(header: Text("ACTIONS")) {
                    Button(action: {
                        if (!self.isOperationPending) {
                            self.isOperationPending = true
                            self.datastore.downloadMlModelAsync { model in
                                if let model = model {
                                    self.videoProcessor.model.model = model
                                }
                                self.isOperationPending = false
                            }
                        }
                    }) {
                        Text("Remove All \(datastore.numberOfTrainingDatasets) Training Data")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.red)
                            .cornerRadius(40)
                    }
                }.padding()
            }
        }
        .padding()
        .navigationBarTitle("Download Neural Net", displayMode: .large)
        .onAppear {
            print("onAppear")
            self.allowLowPrecisionAccumulationOnGPU = self.videoProcessor.model.model.configuration.allowLowPrecisionAccumulationOnGPU
        }
    }
}

struct NetworkManagementView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkManagementView()
    }
}
