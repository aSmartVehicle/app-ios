//
//  ViewHelper.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 22.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI
import Combine


struct IntEntryField : View {
    @State private var enteredValue : String = ""
    @Binding var value : Int

    var body: some View {
        return TextField("", text: $enteredValue)
            .multilineTextAlignment(.trailing)
            .padding(.leading)
            .frame(width: 100.0)
            .onReceive(Just(enteredValue)) { typedValue in
                if let newValue = Int(typedValue) {
                    self.value = newValue
                }
            }.onAppear(perform:{self.enteredValue = "\(self.value)"})
            .keyboardType(.numbersAndPunctuation)
    }
}

struct UIntEntryField : View {
    @State private var enteredValue : String = ""
    @Binding var value : UInt

    var body: some View {
        return TextField("", text: $enteredValue)
            .multilineTextAlignment(.trailing)
            .padding(.leading)
            .frame(width: 100.0)
            .onReceive(Just(enteredValue)) { typedValue in
                if let newValue = UInt(typedValue) {
                    self.value = newValue
                }
            }.onAppear(perform:{self.enteredValue = "\(self.value)"})
            .keyboardType(.numbersAndPunctuation)
    }
}

