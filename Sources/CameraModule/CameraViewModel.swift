//
//  CameraViewModel.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

import AVFoundation
import UIKit

public class CameraViewModel: NSObject, ObservableObject {
    @Published public private(set) var capturedImage: UIImage?
    
    // このViewはパッケージ内部でのみ使用
    var previewView: UIView = UIView()
    
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    
    public override init() {
        super.init()
    }
    
    public func setupCamera() {
        guard session == nil else { return }
        
        guard let device = AVCaptureDevice.default(.builtInWideCamera, for: .video, position: .back) ?? AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back),
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
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = previewView.bounds
        
        // 既存のレイヤーをクリアして追加
        DispatchQueue.main.async {
            self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            self.previewView.layer.addSublayer(videoPreviewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        self.session = session
        self.photoOutput = photoOutput
    }
    
    public func capturePhoto() {
        guard let photoOutput = self.photoOutput else { return }
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    public func stopSession() {
        if let session = self.session, session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.stopRunning()
            }
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
