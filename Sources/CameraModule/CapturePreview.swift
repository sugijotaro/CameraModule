//
//  CapturePreview.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI
import AVFoundation

public struct CameraPreview: UIViewRepresentable {
    @ObservedObject var viewModel: CameraViewModel
    
    public init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
    }
    
    public func makeUIView(context: Context) -> UIView {
        return viewModel.previewView
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}
