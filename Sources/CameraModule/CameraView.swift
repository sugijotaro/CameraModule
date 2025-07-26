//
//  CameraView.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI

public struct CameraView: View {
    @StateObject private var viewModel: CameraViewModel
    private var onImageCaptured: (UIImage) -> Void
    private var onVideoCaptured: ((URL) -> Void)?
    
    @State private var gestureZoomFactor: CGFloat = 1.0
    
    public init(
        cameraMode: CameraMode = .photoOnly,
        onImageCaptured: @escaping (UIImage) -> Void,
        onVideoCaptured: ((URL) -> Void)? = nil
    ) {
        self._viewModel = StateObject(wrappedValue: CameraViewModel(cameraMode: cameraMode))
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
                    if viewModel.captureMode == .photo {
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
                    } else {
                        ZStack {
                            Button(action: {
                                if viewModel.isRecording {
                                    viewModel.stopRecording()
                                } else {
                                    viewModel.startRecording()
                                }
                            }) {
                                if viewModel.isRecording {
                                    ZStack {
                                        Circle()
                                            .fill(.clear)
                                            .frame(width: 70, height: 70)
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red)
                                            .frame(width: 35, height: 35)
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 70, height: 70)
                                }
                            }
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 35, height: 35)
                            }
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                        }
                    }
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
