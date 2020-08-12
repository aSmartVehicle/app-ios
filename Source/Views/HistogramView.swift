//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import UIKit
import SwiftUI


class HistogramUiView : UIView {

    var values: [Double]? = nil
    var indexSelected: Int? = nil

    let histogramColor = UIColor.green
    let histogramColorSelected = UIColor.red


    override func draw(_ rect: CGRect) {

        if let v = values, v.count > 0 {
            let trafo = CGAffineTransform.identity.translatedBy(x: 0, y: self.bounds.height).scaledBy(x: self.bounds.width/CGFloat(v.count), y: -self.bounds.height)
            for i in 0..<v.count {
                if i == indexSelected {
                    histogramColorSelected.setFill()
                } else {
                    histogramColor.setFill()
                }
                let rect = CGRect(x: 0.1 + Double(i), y: 0.0, width: 0.8, height: v[i])
                let path = UIBezierPath(rect: rect)
                path.apply(trafo)
                path.fill()
            }
        }
    }
    
}

struct HistogramView: View {
    var values: [Double]
    var scaleMax: Double
    var indexSelected: Int?

    struct BarShapes: Shape {
        var values: [Double]
        var maxValue: Double

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // draw everything in a (0...barCount, 0...scaleMax) coordinate system
            for barIndex in 0..<values.count {
                var bar = Path()
                bar.addRect(CGRect(x: CGFloat(0.2) + CGFloat(barIndex), y: 0, width: 0.6, height: CGFloat(values[barIndex])))
                
                let trafo = CGAffineTransform(translationX: 0, y: rect.height).scaledBy(x: rect.width/CGFloat(values.count), y: -rect.height/CGFloat(maxValue))
                path.addPath( bar.applying(trafo) )
            }

            return path
        }
    }

    var body: some View {
        ZStack {
            BarShapes(values: values, maxValue: 1.0)
                .stroke(Color.blue, lineWidth: 2)
        }.frame(idealWidth: .infinity, idealHeight: 100, maxHeight: 100)
    }
}

struct HistogramView_Previews: PreviewProvider {
    static var previews: some View {
        let histogramView = HistogramView(values: [1,0,5,2,0,1], scaleMax: 1, indexSelected: 2)
        return histogramView
    }
}
