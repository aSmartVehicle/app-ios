//
//  ContentView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 21.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI
import Combine


struct AppView: View {
    var body: some View {
        TabView {
            InferenceView()
                .tabItem {
                    Image(systemName: "car.fill")
                    Text("Drive")
            }

            TrainingView()
                .tabItem {
                    Image(systemName: "tram.fill")
                    Text("Training")
            }

            MeasurementView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Measurement")
            }

            PreferencesView()
                .tabItem {
                    Image(systemName: "slider.horizontal.3")
                    Text("Settings")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AppView()
    }
}
