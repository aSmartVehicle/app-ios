//
//  RoiView.swift
//  UdpLatencyEstimatorIos
//
//  Created by Claus Fühner on 25.07.20.
//  Copyright © 2020 Claus Fühner. All rights reserved.
//

import SwiftUI



struct ModeView: View {
    var mode: Mode? {
        didSet {
            switch (mode) {
            case .stop:
                color = .red
                text = "S"
            case .manual:
                color = .green
                text = "M"
            case .auto:
                color = .blue
                text = "A"
            default:
                color = .red
                text = "?"
            }
            print("\(String(describing: mode))")
        }
    }
    @State var color: Color = .red
    @State var text: String = "?"

    var body: some View {
        GeometryReader { geo in
            Text("S").foregroundColor(.red).padding()
                .overlay(Circle().stroke(Color.red, lineWidth: 2).padding(10))
                .offset(CGSize(width: geo.size.width * 0.43, height: -geo.size.height * 0.4))
        }
    }
}

struct AnnotatedImageView: View {
    @ObservedObject var videoProcessor = VideoProcessor.sharedInstance
    @ObservedObject var car = Car.sharedInstance

    struct ScaleWithIndicator: Shape {
        var value: Float?
        var trafo: CGAffineTransform

        func path(in rect: CGRect) -> Path {
            var path = Path()

            // draw everything in a (-1...1) coordinate system
            var scale = Path()
            scale.move   (to: CGPoint(x: -0.9,y: -0.06))
            scale.addLine(to: CGPoint(x: -0.9, y: -0.02))
            scale.addLine(to: CGPoint(x:  0.0, y: -0.02))
            scale.addLine(to: CGPoint(x:  0.0, y: -0.04))
            scale.addLine(to: CGPoint(x:  0.0, y: -0.02))
            scale.addLine(to: CGPoint(x:  0.9, y: -0.02))
            scale.addLine(to: CGPoint(x:  0.9, y: -0.06))

            var indicator = Path()
            indicator.move   (to: CGPoint(x: -0.02, y: -0.07))
            indicator.addLine(to: CGPoint(x: -0.02, y: -0.045))
            indicator.addLine(to: CGPoint(x:  0.00, y: -0.02))
            indicator.addLine(to: CGPoint(x:  0.02, y: -0.045))
            indicator.addLine(to: CGPoint(x:  0.02, y: -0.07))
            indicator.closeSubpath()

            let trafoBase = CGAffineTransform(translationX: rect.width/2, y: rect.height/2).scaledBy(x: rect.width/2, y: -rect.height/2)
            path.addPath( scale
                .applying(trafo
                    .concatenating(trafoBase)) )
            if let value = value {
                let trafoIndicator = CGAffineTransform(translationX: CGFloat(0.9 * value), y: 0)
                path.addPath( indicator
                    .applying(trafoIndicator
                        .concatenating(trafo)
                        .concatenating(trafoBase)) )
            }

            return path
        }
    }

    var body: some View {
        VStack {
            if (videoProcessor.scaledUiImage != nil) {
                Image(uiImage: videoProcessor.scaledUiImage!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(ZStack {
                        // bottom scale/indicator
                        ScaleWithIndicator(value: car.autoSteering, trafo: CGAffineTransform(translationX: 0.0, y: -1.0).scaledBy(x: 1.0, y: -1.0))
                            .stroke(Color.blue, lineWidth: 2)
                        // right indicator
                        ScaleWithIndicator(value: car.autoThrottle, trafo: CGAffineTransform(translationX: 1.0, y: 0.0).rotated(by: CGFloat.pi/2).scaledBy(x: 1.0, y: -1.0))
                            .stroke(Color.blue, lineWidth: 2)
                        // top scale/indicator
                        ScaleWithIndicator(value: car.manualSteering, trafo: CGAffineTransform(translationX: 0.0, y: 1.0))
                            .stroke(Color.green, lineWidth: 2)
                        // left scale/indicator
                        ScaleWithIndicator(value: car.manualThrottle, trafo: CGAffineTransform(translationX: -1.0, y: 0.0).rotated(by: CGFloat.pi/2))
                            .stroke(Color.green, lineWidth: 2)
                        //ModeView(mode: car.mode)
                    })
            }
        }
    }
}


struct AnnotatedImageView_Previews: PreviewProvider {
    static var previews: some View {
        AnnotatedImageView()
    }
}
