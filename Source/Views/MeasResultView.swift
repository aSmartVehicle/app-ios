//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  MeasurementResultView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI

struct MeasResultView: View {
    var result: String

    var body: some View {
        VStack {
            ScrollView {
                Text("\(result)")
            }.frame(minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading)
        }.navigationBarTitle("Result", displayMode: .inline)
        .navigationBarItems(
            trailing:
                Button("Copy") {
                    print("Copy Result to Clipboard:\n\(self.result)")
                    UIPasteboard.general.string = self.result
                }
        )
    }
}

struct MeasurementResultView_Previews: PreviewProvider {
    static var previews: some View {
        MeasResultView(result: "This in an example result")
    }
}
