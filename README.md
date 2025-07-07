# CameraModule

[日本語Readmeはこちら](README.ja.md)

`CameraModule` is a Swift Package that makes it easy to implement a feature-rich camera in your SwiftUI apps. You can integrate a camera with just a few lines of code using its default UI component, or build a fully custom user interface for more flexibility.

## Features

- **SwiftUI Native**: Seamlessly integrates with SwiftUI.
- **Photo Capture**: Supports high-resolution photo capture.
- **Camera Switching**: Easily switch between front and back cameras.
- **Smooth Zoom**: Intuitive pinch-to-zoom functionality.
- **Wide-Angle Support**: Supports switching to the wide-angle lens on devices with dual or triple cameras.
- **Flexible Customization**: Use `CameraViewModel` and `CameraPreview` directly to build your own custom camera UI.

## Requirements

- iOS 12.0+

## Installation

You can easily add `CameraModule` to your project using Swift Package Manager.

1.  In Xcode, open your project and select `File` > `Add Packages...`.
2.  Paste the repository URL into the search bar:
    ```
    https://github.com/sugijotaro/CameraModule.git 
    ```
3.  Click `Add Package` to add the library to your project.

## Usage

### 1. Project Setup

To use the camera, you must add a description to your `Info.plist` file to request camera access permission from the user.

Open your project settings in Xcode, go to the `Info` tab, and add the following key to `Custom iOS Target Properties`:

- **Key**: `Privacy - Camera Usage Description`
- **Value**: `This app uses the camera to take photos.` (or any appropriate description)

### 2. Basic Usage (Default UI)

The easiest way to get started is by using the provided `CameraView`. It includes all the basic UI elements for capturing photos, switching cameras, and zooming.

```swift
import SwiftUI
import CameraModule

struct MyContentView: View {
    @State private var capturedImage: UIImage?
    @State private var isShowingCamera = false

    var body: some View {
        VStack {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                Button("Retake Photo") {
                    capturedImage = nil
                }
            } else {
                Button("Launch Camera") {
                    isShowingCamera = true
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraView { image in
                // Receive the captured image (UIImage)
                self.capturedImage = image
                self.isShowingCamera = false
            }
        }
    }
}
```

### 3. Custom UI Usage

For more flexibility and a custom UI, you can use `CameraViewModel` and `CameraPreview` directly. This allows you to design your own layout for the preview and controls.

The example below demonstrates how to place the camera preview in the center of the screen with custom buttons below it.

```swift
import SwiftUI
import CameraModule

struct CustomCameraView: View {
    // Instantiate and use the ViewModel directly
    @StateObject private var viewModel = CameraViewModel()
    
    // Callback for when an image is captured
    private var onImageCaptured: (UIImage) -> Void
    
    init(onImageCaptured: @escaping (UIImage) -> Void) {
        self.onImageCaptured = onImageCaptured
    }
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(viewModel: viewModel)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                HStack {
                    // Camera switch button
                    Button(action: {
                        viewModel.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Capture button
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.setupCamera()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .onChange(of: viewModel.capturedImage) { newImage in
            // Process the captured image
            if let image = newImage {
                onImageCaptured(image)
            }
        }
    }
}
```

## Sample App

The `/sample` directory in this repository contains a demo app, `CameraDemoApp`, that showcases both basic and custom UI implementations of `CameraModule`.

To see it in action, open `sample/CameraDemoApp/CameraDemoApp.xcodeproj` in Xcode and run it on a physical device (required for camera access).

## License

This project is released under the [MIT License](LICENSE).