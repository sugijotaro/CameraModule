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
    @Published public private(set) var currentZoomFactorForDisplay: CGFloat = 1.0
    @Published public private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    
    var previewView: UIView
    
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private let sessionQueue = DispatchQueue(label: "com.CameraModule.sessionQueue")
    
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var activeDevice: AVCaptureDevice?
    
    private var wideAngleZoomFactor: CGFloat = 2.0
    
    @MainActor
    public override init() {
        self.previewView = UIView()
        super.init()
    }
    
    public func setupCamera() {
        checkCameraPermission { [weak self] granted in
            if granted {
                self?.setupCamera(position: .back)
            }
        }
    }
    
    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async { [weak self] in
            self?.cameraPermissionStatus = status
        }
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { [weak self] in
                    self?.cameraPermissionStatus = granted ? .authorized : .denied
                }
                completion(granted)
            }
        default:
            completion(false)
        }
    }
    
    public func switchCamera() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        setupCamera(position: cameraPosition)
    }
    
    private func setupCamera(position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let session = self.session ?? AVCaptureSession()
            
            if let existingSession = self.session {
                existingSession.stopRunning()
                existingSession.inputs.forEach { existingSession.removeInput($0) }
            }
            
            let deviceTypes: [AVCaptureDevice.DeviceType]
            if #available(iOS 13.0, *) {
                deviceTypes = [.builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera]
            } else {
                deviceTypes = [.builtInDualCamera, .builtInWideAngleCamera]
            }
            
            let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: deviceTypes,
                mediaType: .video,
                position: position
            )
            
            guard let device = deviceDiscoverySession.devices.first,
                  let deviceInput = try? AVCaptureDeviceInput(device: device) else {
                print("Camera Error: Could not find or create device input for position \(position).")
                if position != .back { self.setupCamera(position: .back) }
                return
            }
            
            self.activeDevice = device
            
            if let factors = device.virtualDeviceSwitchOverVideoZoomFactors as? [NSNumber], factors.count > 0 {
                self.wideAngleZoomFactor = CGFloat(factors[0].floatValue)
            } else {
                self.wideAngleZoomFactor = 2.0
            }
            
            session.sessionPreset = .photo
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let photoOutput = self.photoOutput ?? AVCapturePhotoOutput()
            if session.canAddOutput(photoOutput) {
                if !session.outputs.contains(where: { $0 === photoOutput }) {
                    session.addOutput(photoOutput)
                }
                
                if #available(iOS 16.0, *) {
                    if let maxDimensions = device.activeFormat.supportedMaxPhotoDimensions.max(by: { $0.width < $1.width }) {
                        photoOutput.maxPhotoDimensions = maxDimensions
                    }
                }
            }
            
            self.setInitialZoom()
            
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
    
    public func zoom(factor: CGFloat) {
        sessionQueue.async { [weak self] in
            guard let self = self, let device = self.activeDevice else { return }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = max(device.minAvailableVideoZoomFactor, min(factor, device.maxAvailableVideoZoomFactor))
                
                self.updateDisplayZoomFactor(device: device)
                
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    private func updateDisplayZoomFactor(device: AVCaptureDevice) {
        let displayFactor: CGFloat
        if device.deviceType == .builtInDualWideCamera || device.deviceType == .builtInTripleCamera {
            displayFactor = device.videoZoomFactor / self.wideAngleZoomFactor
        } else {
            displayFactor = device.videoZoomFactor
        }
        
        DispatchQueue.main.async {
            self.currentZoomFactorForDisplay = round(displayFactor * 10) / 10.0
        }
    }
    
    private func setInitialZoom() {
        guard let device = self.activeDevice else { return }
        do {
            try device.lockForConfiguration()
            if device.position == .front || (device.deviceType != .builtInDualWideCamera && device.deviceType != .builtInTripleCamera) {
                device.videoZoomFactor = 1.0
            } else {
                device.videoZoomFactor = self.wideAngleZoomFactor
            }
            self.updateDisplayZoomFactor(device: device)
            device.unlockForConfiguration()
        } catch {
            print("Could not set initial zoom: \(error)")
        }
    }
    
    public func toggleZoom(to targetDisplayFactor: CGFloat) {
        guard let device = self.activeDevice else { return }
        
        let targetVideoZoomFactor: CGFloat
        if device.deviceType == .builtInDualWideCamera || device.deviceType == .builtInTripleCamera {
            targetVideoZoomFactor = targetDisplayFactor * self.wideAngleZoomFactor
        } else {
            targetVideoZoomFactor = targetDisplayFactor
        }
        
        let currentDisplayFactor = round((device.videoZoomFactor / self.wideAngleZoomFactor) * 10) / 10.0
        
        if abs(currentDisplayFactor - targetDisplayFactor) < 0.1 {
            zoom(factor: self.wideAngleZoomFactor)
        } else {
            zoom(factor: targetVideoZoomFactor)
        }
    }
    
    public func capturePhoto() {
        sessionQueue.async { [weak self] in
            guard let self = self, let photoOutput = self.photoOutput, let device = self.activeDevice else { return }
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
