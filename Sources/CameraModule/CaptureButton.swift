//
//  CaptureButton.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/27.
//

import SwiftUI

struct CaptureButton: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var showCaptureAnimation: Bool
    
    var body: some View {
        ZStack {
            switch (viewModel.cameraMode, viewModel.captureMode) {
            case (.seamless, _):
                SeamlessCaptureButton(viewModel: viewModel, showCaptureAnimation: $showCaptureAnimation)
            case (_, .photo):
                PhotoCaptureButton(viewModel: viewModel, showCaptureAnimation: $showCaptureAnimation)
            case (_, .video):
                VideoCaptureButton(viewModel: viewModel, showCaptureAnimation: $showCaptureAnimation)
            }
        }
    }
}

// MARK: - Photo Capture Button
struct PhotoCaptureButton: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var showCaptureAnimation: Bool
    
    var body: some View {
        ZStack {
            Button(action: {
                viewModel.capturePhoto()
                withAnimation(.easeOut(duration: 0.3)) {
                    showCaptureAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showCaptureAnimation = false
                }
            }) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .scaleEffect(showCaptureAnimation ? 0.8 : 1.0)
            }
            .disabled(viewModel.isProcessingCapture)
            
            if viewModel.isProcessingCapture {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                    .scaleEffect(1.5)
            }
            
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 80, height: 80)
        }
    }
}

// MARK: - Video Capture Button
struct VideoCaptureButton: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var showCaptureAnimation: Bool
    
    var body: some View {
        ZStack {
            Button(action: {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCaptureAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCaptureAnimation = false
                    }
                }
            }) {
                if viewModel.isRecording {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.01))
                            .frame(width: 70, height: 70)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 35, height: 35)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                    }
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                        .scaleEffect(showCaptureAnimation ? 0.8 : 1.0)
                }
            }
            .disabled(viewModel.isProcessingVideo)
            
            if viewModel.isProcessingVideo {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 80, height: 80)
        }
    }
}

// MARK: - Seamless Capture Button
struct SeamlessCaptureButton: View {
    @ObservedObject var viewModel: CameraViewModel
    @Binding var showCaptureAnimation: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(viewModel.isRecording ? Color.red : Color.white)
                .frame(width: 70, height: 70)
                .scaleEffect(viewModel.isRecording ? 0.8 : (showCaptureAnimation ? 0.8 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
                .animation(.easeOut(duration: 0.3), value: showCaptureAnimation)
                .onTapGesture {
                    if !viewModel.isRecording {
                        viewModel.capturePhoto()
                        withAnimation(.easeOut(duration: 0.3)) {
                            showCaptureAnimation = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showCaptureAnimation = false
                        }
                    }
                }
                .onLongPressGesture(
                    minimumDuration: 0.5,
                    maximumDistance: .infinity,
                    pressing: { isPressing in
                        if isPressing && !viewModel.isRecording {
                            viewModel.startRecording()
                        } else if !isPressing && viewModel.isRecording {
                            viewModel.stopRecording()
                        }
                    },
                    perform: { }
                )
            
            if viewModel.isProcessingCapture && !viewModel.isRecording {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
            
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 80, height: 80)
        }
    }
}
