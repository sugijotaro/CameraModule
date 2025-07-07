//
//  CameraView.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI

public struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    private var onImageCaptured: (UIImage) -> Void
    
    @State private var currentZoomFactor: CGFloat = 1.0
    
    public init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    public var body: some View {
        ZStack {
            CameraPreview(viewModel: viewModel)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value - 1.0
                            let newZoomFactor = currentZoomFactor + delta
                            viewModel.zoom(factor: newZoomFactor)
                        }
                        .onEnded { value in
                            let newZoomFactor = currentZoomFactor + (value - 1.0)
                            currentZoomFactor = newZoomFactor
                        }
                )
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    ZStack {
                        Button(action: {
                            viewModel.capturePhoto()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 70, height: 70)
                        }
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button(action: {
                        currentZoomFactor = 1.0
                        viewModel.zoom(factor: 1.0)
                        viewModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 30)
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
    }
}
