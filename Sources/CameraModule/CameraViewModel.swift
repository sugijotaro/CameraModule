//
//  CameraViewModel.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

@preconcurrency import AVFoundation
import UIKit

public class CameraViewModel: NSObject, ObservableObject, @unchecked Sendable {
    @Published public private(set) var capturedImage: UIImage?
    
    var previewView: UIView
    
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private let sessionQueue = DispatchQueue(label: "com.CameraModule.sessionQueue")
    
    @MainActor
    public override init() {
        self.previewView = UIView()
        super.init()
    }
    
    public func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            guard self.session == nil else { return }
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) ?? AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back),
                  let deviceInput = try? AVCaptureDeviceInput(device: device) else {
                print("Camera Error: Could not create device input.")
                return
            }
            
            let session = AVCaptureSession()
            session.sessionPreset = .photo
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let photoOutput = AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
            }
            
            DispatchQueue.main.async {
                let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                videoPreviewLayer.videoGravity = .resizeAspectFill
                videoPreviewLayer.frame = self.previewView.bounds
                
                self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                self.previewView.layer.addSublayer(videoPreviewLayer)
            }
            
            session.startRunning()
            
            self.session = session
            self.photoOutput = photoOutput
        }
    }
    
    public func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self, let photoOutput = self.photoOutput else { return }
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    public func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, let session = self.session, session.isRunning else { return }
            session.stopRunning()
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            print("Camera Error: \(error.localizedDescription)")
            return
        }
        if let data = photo.fileDataRepresentation(), let image = UIImage(data: data) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}
