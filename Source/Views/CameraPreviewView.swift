//
//  ASV - Autonomous {Smart, Simple, Self-Driving} Vehicle
//  CameraPreviewView.swift
//
//  Copyright © 2020 the ASV team. See LICENSE.md for legal information.
//

import SwiftUI
import UIKit
import AVFoundation
/*
class CameraPreviewUiView: UIView {
    private var videoSource: VideoSource = VideoSource.sharedInstance

    init() {
        super.init(frame: .zero)
    }

    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if nil != self.superview {
            self.videoPreviewLayer.session = self.videoSource.getCaptureSession()
            self.videoPreviewLayer.videoGravity = .resizeAspect
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    typealias UIViewType = CameraPreviewUiView
    
    func makeUIView(context: UIViewRepresentableContext<CameraPreviewView>) -> CameraPreviewUiView {
        CameraPreviewUiView()
    }

    func updateUIView(_ uiView: CameraPreviewUiView, context: UIViewRepresentableContext<CameraPreviewView>) {
    }
}
*/
