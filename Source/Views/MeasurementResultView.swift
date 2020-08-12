//
//  MeasurementResultView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 29.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct MeasResultView: View {
    var result: String

    var body: some View {
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
                Text("\(result)")
            }
        }.navigationBarTitle("Result", displayMode: .inline)
    }
}

struct MeasurementResultView_Previews: PreviewProvider {
    static var previews: some View {
        MeasResultView(result: "This in an example result")
    }
}
