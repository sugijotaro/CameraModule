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
    
    private var cameraPosition: AVCaptureDevice.Position = .back
    
    @MainActor
    public override init() {
        self.previewView = UIView()
        super.init()
    }
    
    public func setupCamera() {
        setupCamera(position: .back)
    }
    
    public func switchCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        setupCamera(position: cameraPosition)
    }
    
    private func setupCamera(position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let existingSession = self.session {
                existingSession.stopRunning()
                existingSession.inputs.forEach { existingSession.removeInput($0) }
                existingSession.outputs.forEach { existingSession.removeOutput($0) }
            }
            
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                mediaType: .video,
                position: position
            )
            
            guard let device = deviceDiscoverySession.devices.first,
                  let deviceInput = try? AVCaptureDeviceInput(device: device) else {
                print("Camera Error: Could not find or create device input for position \(position).")
                if position != .back {
                    self.setupCamera(position: .back)
                }
                return
            }
            
            let session = self.session ?? AVCaptureSession()
            session.sessionPreset = .photo
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let photoOutput = self.photoOutput ?? AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) && session.outputs.isEmpty {
                session.addOutput(photoOutput)
            }
            
            DispatchQueue.main.async {
                if let previewLayer = self.previewView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                    previewLayer.session = session
                } else {
                    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: session)
                    videoPreviewLayer.videoGravity = .resizeAspectFill
                    videoPreviewLayer.frame = self.previewView.bounds
                    
                    self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                    self.previewView.layer.addSublayer(videoPreviewLayer)
                }
            }
            
            if !session.isRunning {
                session.startRunning()
            }
            
            self.session = session
            self.photoOutput = photoOutput
        }
    }
    
    public func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self, let photoOutput = self.photoOutput else { return }
            let settings = AVCapturePhotoSettings()
            if self.cameraPosition == .front {
                if let connection = photoOutput.connection(with: .video) {
                    connection.isVideoMirrored = true
                }
            }
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
        if let data = photo.fileDataRepresentation(), var image = UIImage(data: data) {
            
            if self.cameraPosition == .front {
                if let cgImage = image.cgImage {
                    image = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
                }
            }
            
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}
