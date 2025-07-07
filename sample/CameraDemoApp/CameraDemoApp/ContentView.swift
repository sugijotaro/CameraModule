//
//  ContentView.swift
//  CameraDemoApp
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import SwiftUI
import CameraModule

struct ContentView: View {
    @State private var capturedImage: UIImage?
    @State private var isShowingCameraModuleView = false
    @State private var isShowingCustomCameraView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let image = capturedImage {
                    Spacer()
                    Text("Captured Image")
                        .font(.headline)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 5)
                        .padding()
                    
                    Button {
                        capturedImage = nil
                    } label: {
                        Label("Take Another Photo", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                    Spacer()
                    
                } else {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "camera.on.rectangle")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("Camera Demo App")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Choose a camera style to take a photo.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Button {
                            isShowingCameraModuleView = true
                        } label: {
                            Label("Default Fullscreen Camera", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button {
                            isShowingCustomCameraView = true
                        } label: {
                            Label("Custom UI Camera", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isShowingCameraModuleView) {
                CameraView { image in
                    self.capturedImage = image
                    self.isShowingCameraModuleView = false
                }
            }
            .fullScreenCover(isPresented: $isShowingCustomCameraView) {
                CustomCameraView { image in
                    self.capturedImage = image
                    self.isShowingCustomCameraView = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
