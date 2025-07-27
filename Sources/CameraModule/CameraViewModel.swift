//
//  CameraViewModel.swift
//  CameraModule
//
//  Created by Jotaro Sugiyama on 2025/07/07.
//

@preconcurrency import AVFoundation
import UIKit

public enum CameraMode {
    case photoOnly
    case photoAndVideo
    case seamless
}

public enum CaptureMode: String, CaseIterable {
    case photo = "Photo"
    case video = "Video"
}

public struct VideoResolution : Sendable{
    public let width: Int
    public let height: Int
    public let sessionPreset: AVCaptureSession.Preset?
    
    public init(width: Int, height: Int, sessionPreset: AVCaptureSession.Preset? = nil) {
        self.width = width
        self.height = height
        self.sessionPreset = sessionPreset
    }
    
    public static let hd1920x1080 = VideoResolution(width: 1920, height: 1080, sessionPreset: .hd1920x1080)
    public static let hd1280x720 = VideoResolution(width: 1280, height: 720, sessionPreset: .hd1280x720)
    public static let hd4K3840x2160 = VideoResolution(width: 3840, height: 2160, sessionPreset: .hd4K3840x2160)
    public static let vga640x480 = VideoResolution(width: 640, height: 480, sessionPreset: .vga640x480)
    public static let iFrame960x540 = VideoResolution(width: 960, height: 540, sessionPreset: .iFrame960x540)
    public static let iFrame1280x720 = VideoResolution(width: 1280, height: 720, sessionPreset: .iFrame1280x720)
    
    public static func custom(width: Int, height: Int) -> VideoResolution {
        return VideoResolution(width: width, height: height, sessionPreset: nil)
    }
}

public class CameraViewModel: NSObject, ObservableObject, @unchecked Sendable {
    @Published public private(set) var capturedImage: UIImage?
    @Published public private(set) var currentZoomFactorForDisplay: CGFloat = 1.0
    @Published public private(set) var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @Published public private(set) var isRecording: Bool = false
    @Published public private(set) var recordedVideoURL: URL?
    @Published public var captureMode: CaptureMode = .photo
    @Published public private(set) var isProcessingCapture: Bool = false
    
    var previewView: UIView
    let cameraMode: CameraMode
    private let sessionPreset: AVCaptureSession.Preset
    private let videoResolution: VideoResolution?
    
    private var session: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private let sessionQueue = DispatchQueue(label: "com.CameraModule.sessionQueue")
    
    private var cameraPosition: AVCaptureDevice.Position = .back
    private var activeDevice: AVCaptureDevice?
    
    private var wideAngleZoomFactor: CGFloat = 2.0
    
    @MainActor
    public init(cameraMode: CameraMode = .photoOnly, sessionPreset: AVCaptureSession.Preset = .photo, videoResolution: VideoResolution? = nil) {
        self.previewView = UIView()
        self.cameraMode = cameraMode
        self.sessionPreset = sessionPreset
        self.videoResolution = videoResolution
        super.init()
    }
    
    public func setupCamera() {
        Task {
            checkCameraPermission { [weak self] granted in
                if granted {
                    self?.setupCamera(position: .back)
                }
            }
        }
    }
    
    private func checkCameraPermission(completion: @escaping @Sendable (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        DispatchQueue.main.async { [weak self] in
            self?.cameraPermissionStatus = status
        }
        
        switch status {
        case .authorized:
            if cameraMode == .photoAndVideo || cameraMode == .seamless {
                checkMicrophonePermission(completion: completion)
            } else {
                completion(true)
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    self?.cameraPermissionStatus = granted ? .authorized : .denied
                    if granted {
                        if self?.cameraMode == .photoAndVideo || self?.cameraMode == .seamless {
                            self?.checkMicrophonePermission(completion: completion)
                        } else {
                            completion(true)
                        }
                    } else {
                        completion(false)
                    }
                }
            }
        default:
            completion(false)
        }
    }
    
    private func checkMicrophonePermission(completion: @escaping @Sendable (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                completion(granted)
            }
        default:
            completion(true)
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
            
            if session.canSetSessionPreset(self.sessionPreset) {
                session.sessionPreset = self.sessionPreset
            } else {
                // Fallback to photo preset if the specified preset is not supported
                session.sessionPreset = .photo
            }
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            // Apply custom video resolution if specified
            if let videoResolution = self.videoResolution, videoResolution.sessionPreset == nil {
                self.applyCustomVideoResolution(videoResolution, to: device)
            }
            
            if cameraMode == .photoAndVideo || cameraMode == .seamless {
                if let audioDevice = AVCaptureDevice.default(for: .audio),
                   let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                   session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
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
            
            if cameraMode == .photoAndVideo || cameraMode == .seamless {
                let movieOutput = self.movieOutput ?? AVCaptureMovieFileOutput()
                if session.canAddOutput(movieOutput) {
                    if !session.outputs.contains(where: { $0 === movieOutput }) {
                        session.addOutput(movieOutput)
                    }
                }
                self.movieOutput = movieOutput
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
    
    public func startRecording() {
        guard cameraMode == .photoAndVideo || cameraMode == .seamless else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let movieOutput = self.movieOutput,
                  !movieOutput.isRecording else { return }
            
            let outputURL = self.generateVideoFileURL()
            
            if let connection = movieOutput.connection(with: .video) {
                if self.cameraPosition == .front {
                    connection.isVideoMirrored = true
                }
            }
            
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            
            DispatchQueue.main.async {
                self.isRecording = true
            }
        }
    }
    
    public func stopRecording() {
        guard cameraMode == .photoAndVideo || cameraMode == .seamless else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let movieOutput = self.movieOutput,
                  movieOutput.isRecording else { return }
            
            movieOutput.stopRecording()
        }
    }
    
    private func generateVideoFileURL() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".mov"
        return tempDirectory.appendingPathComponent(fileName)
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
        DispatchQueue.main.async { [weak self] in
            self?.isProcessingCapture = true
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, let photoOutput = self.photoOutput, let device = self.activeDevice else { 
                DispatchQueue.main.async {
                    self?.isProcessingCapture = false
                }
                return 
            }
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
                self.isProcessingCapture = false
            }
        }
    }
    
    private func applyCustomVideoResolution(_ resolution: VideoResolution, to device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            let formats = device.formats.filter { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width == Int32(resolution.width) && dimensions.height == Int32(resolution.height)
            }
            
            if let bestFormat = formats.first {
                device.activeFormat = bestFormat
                
                let targetFrameRate = 30.0
                let ranges = bestFormat.videoSupportedFrameRateRanges
                if let range = ranges.first(where: { $0.minFrameRate <= targetFrameRate && targetFrameRate <= $0.maxFrameRate }) {
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate))
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(targetFrameRate))
                }
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Could not set custom video resolution: \(error)")
        }
    }
}

extension CameraViewModel: AVCaptureFileOutputRecordingDelegate {
    public func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = false
            
            if let error = error {
                print("Video recording error: \(error.localizedDescription)")
                return
            }
            
            self?.recordedVideoURL = outputFileURL
        }
    }
}
