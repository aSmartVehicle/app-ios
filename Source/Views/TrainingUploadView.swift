//
//  TrainingUploadView.swift
//  ASV
//
//  Created by Claus Fühner on 06.08.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct TrainingDataManagementView: View {
    @ObservedObject var datastore = Datastore.sharedInstance
    @State var isOperationPending: Bool = false

    var body: some View {
        VStack {
            Text("Upload recorded data to a remote server via SSH.")
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
            }
            Spacer()
            if (self.isOperationPending) {
                Section(header: Text("PROGRESS")) {
                    Text(datastore.currentStatus)
                    Text("\(datastore.currentCompletionPercent, specifier: "%0.0f")% complete")
                }.padding()
                Spacer()
            }
            if (!self.isOperationPending) {
                Section(header: Text("ACTIONS")) {
                    Button(action: {
                        if (!self.isOperationPending) {
                            self.isOperationPending = true
                            self.datastore.deleteAllTrainingDataAsync {
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
                    Button(action: {
                        if (!self.isOperationPending) {
                            self.isOperationPending = true
                            self.datastore.moveTrainingDataToHostAsync {
                                self.isOperationPending = false
                            }
                        }
                    }) {
                        Text("Upload & Remove \(datastore.numberOfTrainingDatasets) Training Data")
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.green)
                            .cornerRadius(40)
                    }
                }.padding()
            }
        }
        .padding()
        .navigationBarTitle("Upload Training Data", displayMode: .large)
    }
}

struct TrainingUploadView_Previews: PreviewProvider {
    static var previews: some View {
        TrainingDataManagementView()
    }
}
