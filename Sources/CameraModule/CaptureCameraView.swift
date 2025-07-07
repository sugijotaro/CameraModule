//
//  CaptureCameraView.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI

public struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    private var onImageCaptured: (UIImage) -> Void
    
    public init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    public var body: some View {
        ZStack {
            CameraPreview(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                Button(action: {
                    viewModel.capturePhoto()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedImage) { oldImage, newImage in
            if let image = newImage {
                onImageCaptured(image)
            }
        }
    }
}
