//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  MeasUdpLtcyIntroView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI

struct MeasUdpLtcyIntroView: View {
    var body: some View {
        VStack {
            Text("The measurement needs an Embedded Car Controller as a partner for returning UDP packets.")
                .multilineTextAlignment(.leading)
            Spacer(minLength: 16)
            NavigationLink(destination: MeasUdpLtcySetupView()) {
                Text("Setup Measurement")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(40)
            }
        }
        .padding()
        .navigationBarTitle("UDP Latency", displayMode: .large)
    }
}

struct MeasUdpLtcyInfo_Previews: PreviewProvider {
    static var previews: some View {
        MeasUdpLtcyIntroView()
    }
}
