//
//  MeasurementView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 29.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI

struct MeasurementView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: MeasUdpLtcyIntroView()) {
                    Text("UDP Latency (Round Trip time measurement)")
                }
                NavigationLink(destination: MeasOverallLtcyIntroView()) {
                    Text("Overall Latency (including UDP tranmission and camera)")
                }
            }
            .navigationBarTitle("Measurement", displayMode: .inline)
        }
    }
}

struct MeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        MeasurementView()
    }
}
