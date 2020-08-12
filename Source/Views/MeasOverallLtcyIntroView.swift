//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  MeasOverallLtcyIntroView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI

struct MeasOverallLtcyIntroView: View {
    var body: some View {
        VStack {
            /*
            Text("Overall Latency Measurement")
                .font(.title)
                .padding()
            */
            Text("The measurement needs an Embedded Car Controller as a partner for returning UDP packets. Configure the IP connection via Settings.")
                .multilineTextAlignment(.leading)
            Spacer(minLength: 16)
            NavigationLink(destination: MeasOverallLtcySetupView()) {
                Text("Setup Measurement")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.green)
                    .cornerRadius(40)
            }
        }
        .padding()
        .navigationBarTitle("Overall Latency", displayMode: .large)
    }
}

struct MeasOverallLtcyInfo_Previews: PreviewProvider {
    static var previews: some View {
        MeasOverallLtcyIntroView()
    }
}
