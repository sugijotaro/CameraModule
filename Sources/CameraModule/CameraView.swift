//
//  CameraView.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI
import AVFoundation

public struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    private var onImageCaptured: (UIImage) -> Void
    private var onVideoCaptured: ((URL) -> Void)?
    
    @State private var gestureZoomFactor: CGFloat = 1.0
    @State private var showCaptureAnimation = false
    
    public init(
        cameraMode: CameraMode = .photoOnly,
        sessionPreset: AVCaptureSession.Preset = .photo,
        videoResolution: VideoResolution? = nil,
        onImageCaptured: @escaping (UIImage) -> Void,
        onVideoCaptured: ((URL) -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: CameraViewModel(
            cameraMode: cameraMode,
            sessionPreset: sessionPreset,
            videoResolution: videoResolution
        ))
        self.onImageCaptured = onImageCaptured
        self.onVideoCaptured = onVideoCaptured
    }
    
    public var body: some View {
        ZStack {
            CameraPreview(viewModel: viewModel)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newFactor = gestureZoomFactor * value
                            viewModel.zoom(factor: newFactor)
                        }
                        .onEnded { value in
                            gestureZoomFactor *= value
                        }
                )
                .ignoresSafeArea()
            
            VStack {
                Button(action: {
                    viewModel.toggleZoom(to: 0.5)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.gestureZoomFactor = viewModel.currentZoomFactorForDisplay * 2.0
                    }
                }) {
                    Text("\(viewModel.currentZoomFactorForDisplay, specifier: "%.1f")x")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                }
                
                if viewModel.cameraMode == .photoAndVideo {
                    Picker("Mode", selection: $viewModel.captureMode) {
                        ForEach(CaptureMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                    .padding(.bottom, 20)
                }
                
                HStack {
                    CaptureButton(
                        cameraMode: viewModel.cameraMode,
                        captureMode: viewModel.captureMode,
                        isRecording: .init(
                            get: { viewModel.isRecording },
                            set: { _ in }
                        ),
                        isProcessingCapture: .init(
                            get: { viewModel.isProcessingCapture },
                            set: { _ in }
                        ),
                        isProcessingVideo: .init(
                            get: { viewModel.isProcessingVideo },
                            set: { _ in }
                        ),
                        showCaptureAnimation: $showCaptureAnimation,
                        onCapturePhoto: { viewModel.capturePhoto() },
                        onStartRecording: { viewModel.startRecording() },
                        onStopRecording: { viewModel.stopRecording() }
                    )
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    if !viewModel.isRecording {
                        Button(action: {
                            viewModel.switchCamera()
                            self.gestureZoomFactor = 2.0
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
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 30)
            
            // Flash effect for photo capture (only in photo mode or seamless mode when not recording)
            if showCaptureAnimation && (viewModel.captureMode == .photo || (viewModel.cameraMode == .seamless && !viewModel.isRecording)) {
                Color.white
                    .opacity(0.7)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
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
        .onChange(of: viewModel.recordedVideoURL) { newURL in
            if let url = newURL {
                onVideoCaptured?(url)
            }
        }
    }
}
