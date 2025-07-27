//
//  CaptureButton.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/27.
//

import SwiftUI

struct CaptureButton: View {
    let cameraMode: CameraMode
    let captureMode: CaptureMode
    @Binding var isRecording: Bool
    @Binding var isProcessingCapture: Bool
    @Binding var isProcessingVideo: Bool
    @Binding var showCaptureAnimation: Bool
    
    let onCapturePhoto: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        ZStack {
            switch (cameraMode, captureMode) {
            case (.seamless, _):
                SeamlessCaptureButton(
                    isRecording: $isRecording,
                    isProcessingCapture: $isProcessingCapture,
                    showCaptureAnimation: $showCaptureAnimation,
                    onCapturePhoto: onCapturePhoto,
                    onStartRecording: onStartRecording,
                    onStopRecording: onStopRecording
                )
            case (_, .photo):
                PhotoCaptureButton(
                    isProcessingCapture: $isProcessingCapture,
                    showCaptureAnimation: $showCaptureAnimation,
                    onCapturePhoto: onCapturePhoto
                )
            case (_, .video):
                VideoCaptureButton(
                    isRecording: $isRecording,
                    isProcessingVideo: $isProcessingVideo,
                    showCaptureAnimation: $showCaptureAnimation,
                    onStartRecording: onStartRecording,
                    onStopRecording: onStopRecording
                )
            }
        }
    }
}

// MARK: - Photo Capture Button
struct PhotoCaptureButton: View {
    @Binding var isProcessingCapture: Bool
    @Binding var showCaptureAnimation: Bool
    let onCapturePhoto: () -> Void
    
    var body: some View {
        ZStack {
            Button(action: {
                onCapturePhoto()
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
            .disabled(isProcessingCapture)
            
            if isProcessingCapture {
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
    @Binding var isRecording: Bool
    @Binding var isProcessingVideo: Bool
    @Binding var showCaptureAnimation: Bool
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        ZStack {
            Button(action: {
                if isRecording {
                    onStopRecording()
                } else {
                    onStartRecording()
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCaptureAnimation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCaptureAnimation = false
                    }
                }
            }) {
                if isRecording {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.01))
                            .frame(width: 70, height: 70)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                            .frame(width: 35, height: 35)
                            .animation(.easeInOut(duration: 0.2), value: isRecording)
                    }
                } else {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 70, height: 70)
                        .scaleEffect(showCaptureAnimation ? 0.8 : 1.0)
                }
            }
            .disabled(isProcessingVideo)
            
            if isProcessingVideo {
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
    @Binding var isRecording: Bool
    @Binding var isProcessingCapture: Bool
    @Binding var showCaptureAnimation: Bool
    let onCapturePhoto: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red : Color.white)
                .frame(width: 70, height: 70)
                .scaleEffect(isRecording ? 0.8 : (showCaptureAnimation ? 0.8 : 1.0))
                .animation(.easeInOut(duration: 0.2), value: isRecording)
                .animation(.easeOut(duration: 0.3), value: showCaptureAnimation)
                .onTapGesture {
                    if !isRecording {
                        onCapturePhoto()
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
                        if isPressing && !isRecording {
                            onStartRecording()
                        } else if !isPressing && isRecording {
                            onStopRecording()
                        }
                    },
                    perform: { }
                )
            
            if isProcessingCapture && !isRecording {
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

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Photo Capture Button") {
    @Previewable @State var isProcessingCapture = false
    @Previewable @State var showCaptureAnimation = false
    
    ZStack {
        Color.black.ignoresSafeArea()
        PhotoCaptureButton(
            isProcessingCapture: $isProcessingCapture,
            showCaptureAnimation: $showCaptureAnimation,
            onCapturePhoto: { 
                isProcessingCapture = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isProcessingCapture = false
                }
            }
        )
    }
}

@available(iOS 17.0, *)
#Preview("Video Capture Button") {
    @Previewable @State var isRecording = false
    @Previewable @State var isProcessingVideo = false
    @Previewable @State var showCaptureAnimation = false
    
    ZStack {
        Color.black.ignoresSafeArea()
        VideoCaptureButton(
            isRecording: $isRecording,
            isProcessingVideo: $isProcessingVideo,
            showCaptureAnimation: $showCaptureAnimation,
            onStartRecording: { 
                isRecording = true
            },
            onStopRecording: { 
                isRecording = false
                isProcessingVideo = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isProcessingVideo = false
                }
            }
        )
    }
}

@available(iOS 17.0, *)
#Preview("Seamless Capture Button") {
    @Previewable @State var isRecording = false
    @Previewable @State var isProcessingCapture = false
    @Previewable @State var showCaptureAnimation = false
    
    ZStack {
        Color.black.ignoresSafeArea()
        SeamlessCaptureButton(
            isRecording: $isRecording,
            isProcessingCapture: $isProcessingCapture,
            showCaptureAnimation: $showCaptureAnimation,
            onCapturePhoto: { 
                isProcessingCapture = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isProcessingCapture = false
                }
            },
            onStartRecording: { 
                isRecording = true
            },
            onStopRecording: { 
                isRecording = false
            }
        )
    }
}
