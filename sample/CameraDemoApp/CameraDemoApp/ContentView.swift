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
    @State private var isShowingCamera = false
    
    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Button("Retake Photo") {
                    capturedImage = nil
                    isShowingCamera = true
                }
                .padding()
            } else {
                Text("Take a photo with the camera")
                Button("Open Camera") {
                    isShowingCamera = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraView { image in
                self.capturedImage = image
                self.isShowingCamera = false
            }
        }
    }
}

#Preview {
    ContentView()
}
