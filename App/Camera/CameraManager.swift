import AVFoundation
import UIKit

final class CameraManager: NSObject {
    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()

    private var videoInput: AVCaptureDeviceInput?
    private(set) var isUsingFrontCamera = false
    private(set) var isFlashEnabled = false
    private(set) var currentZoomFactor: CGFloat = 1

    var onStatusMessage: ((String) -> Void)?

    func configureSession() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else {
                onStatusMessage?("Camera permission denied")
                return
            }
        default:
            onStatusMessage?("Enable camera permission in Settings")
            return
        }

        sessionQueue.async { [weak self] in
            self?.setupSession()
            self?.session.startRunning()
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd4K3840x2160

        defer { session.commitConfiguration() }

        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

        guard let input = makeDeviceInput(front: isUsingFrontCamera), session.canAddInput(input) else {
            onStatusMessage?("Unable to add camera input")
            return
        }

        session.addInput(input)
        videoInput = input

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.maxPhotoQualityPrioritization = .quality
        }

        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            if let connection = movieOutput.connection(with: .video), connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }

        onStatusMessage?("4K camera is ready")
    }

    private func makeDeviceInput(front: Bool) -> AVCaptureDeviceInput? {
        let position: AVCaptureDevice.Position = front ? .front : .back
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video,
            position: position
        )

        guard let device = discovery.devices.first else { return nil }

        do {
            return try AVCaptureDeviceInput(device: device)
        } catch {
            onStatusMessage?("Camera input error: \(error.localizedDescription)")
            return nil
        }
    }

    func switchCamera() {
        isUsingFrontCamera.toggle()
        sessionQueue.async { [weak self] in
            self?.setupSession()
        }
    }

    func toggleFlash() {
        isFlashEnabled.toggle()
        onStatusMessage?(isFlashEnabled ? "Flash enabled" : "Flash disabled")
    }

    func setZoom(factor: CGFloat) {
        guard let device = videoInput?.device else { return }
        let clamped = min(max(factor, 1), min(device.activeFormat.videoMaxZoomFactor, 10))
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
            currentZoomFactor = clamped
        } catch {
            onStatusMessage?("Zoom error: \(error.localizedDescription)")
        }
    }

    func focus(at point: CGPoint, in viewSize: CGSize) {
        guard let device = videoInput?.device else { return }
        let normalized = CGPoint(x: point.y / viewSize.height, y: 1.0 - (point.x / viewSize.width))

        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = normalized
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = normalized
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            onStatusMessage?("Focus error: \(error.localizedDescription)")
        }
    }

    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = isFlashEnabled ? .on : .off
        settings.photoQualityPrioritization = .quality
        photoOutput.capturePhoto(with: settings, delegate: delegate)
    }

    func startRecording() {
        guard !movieOutput.isRecording else { return }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        movieOutput.startRecording(to: url, recordingDelegate: self)
        onStatusMessage?("Recording 4K video")
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error {
            onStatusMessage?("Recording error: \(error.localizedDescription)")
            return
        }

        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        onStatusMessage?("Video saved")
    }
}
