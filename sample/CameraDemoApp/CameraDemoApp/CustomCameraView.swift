//
//  CustomCameraView.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI
import CameraModule

struct CustomCameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    private var onImageCaptured: (UIImage) -> Void
    
    init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    let previewWidth = geometry.size.width - 40
                    let previewHeight = previewWidth * 4 / 3
                    
                    CameraPreview(viewModel: viewModel)
                        .frame(width: previewWidth, height: previewHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 70, height: 70)
                            }
                        }
                        
                        Spacer()
                        
                        Color.clear.frame(width: 24 + 32, height: 24 + 32)
                        
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 30 : 50)
                }
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedImage) { newImage in
            if let image = newImage {
                onImageCaptured(image)
            }
        }
        .preferredColorScheme(.dark)
    }
}
