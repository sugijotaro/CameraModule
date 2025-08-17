//
//  FixedSizeCameraView.swift
//  CameraDemoApp
//
//  Created by Jotaro Sugiyama on 2025/08/03.
//

import SwiftUI
import CameraModule
import AVFoundation

struct FixedSizeCameraView: View {
    @StateObject private var viewModel = CameraViewModel(cameraMode: .photoAndVideo)
    @State private var isPhotoMode = true
    @State private var isRecording = false
    @State private var recordingStartTime: Date?
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    
    let onImageCaptured: (UIImage) -> Void
    let onVideoCaptured: (URL) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    init(onImageCaptured: @escaping (UIImage) -> Void, onVideoCaptured: @escaping (URL) -> Void) {
        self.onImageCaptured = onImageCaptured
        self.onVideoCaptured = onVideoCaptured
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                let previewWidth: CGFloat = 1024
                let previewHeight: CGFloat = 1536
                let scale = min(geometry.size.width / previewWidth, geometry.size.height / previewHeight)
                let scaledWidth = previewWidth * scale
                let scaledHeight = previewHeight * scale
                
                VStack {
                    Spacer()
                    
                    ZStack {
                        CameraPreview(viewModel: viewModel)
                            .frame(width: scaledWidth, height: scaledHeight)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        VStack {
                            HStack {
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isPhotoMode.toggle()
                                        if !isPhotoMode {
                                            // Prepare for video recording when switching to video mode
                                            viewModel.prepareForVideoRecording()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isPhotoMode ? "camera.fill" : "video.fill")
                                            .font(.system(size: 16))
                                        Text(isPhotoMode ? "Photo" : "Video")
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.6))
                                    .cornerRadius(20)
                                }
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                            }
                            
                            Spacer()
                            
                            if isRecording {
                                HStack {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 12, height: 12)
                                    Text(formatDuration(recordingDuration))
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(20)
                                .padding(.bottom, 20)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 60) {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                        
                        Button(action: {
                            if isPhotoMode {
                                capturePhoto()
                            } else {
                                if isRecording {
                                    stopVideoRecording()
                                } else {
                                    startVideoRecording()
                                }
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 3)
                                    .frame(width: 80, height: 80)
                                
                                if !isPhotoMode && isRecording {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                        .frame(width: 30, height: 30)
                                } else {
                                    Circle()
                                        .fill(isPhotoMode ? Color.white : Color.red)
                                        .frame(width: isPhotoMode ? 70 : 65, height: isPhotoMode ? 70 : 65)
                                }
                            }
                        }
                        
                        Button(action: {
                            viewModel.switchCamera()
                        }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopSession()
            stopRecordingTimer()
        }
        .onChange(of: viewModel.capturedImage) { newImage in
            if let image = newImage {
                onImageCaptured(image)
            }
        }
        .onChange(of: viewModel.recordedVideoURL) { newURL in
            if let url = newURL {
                onVideoCaptured(url)
            }
        }
    }
    
    private func capturePhoto() {
        viewModel.capturePhoto()
    }
    
    private func startVideoRecording() {
        isRecording = true
        recordingStartTime = Date()
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = recordingStartTime {
                recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
        
        viewModel.startRecording()
    }
    
    private func stopVideoRecording() {
        isRecording = false
        stopRecordingTimer()
        
        viewModel.stopRecording()
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
        recordingStartTime = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
