import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class CameraViewModel: NSObject, ObservableObject {
    let manager = CameraManager()

    @Published var isVideoMode = false
    @Published var isRecording = false
    @Published var isFlashEnabled = false
    @Published var currentZoom: CGFloat = 1
    @Published var statusMessage: String?

    override init() {
        super.init()
        manager.onStatusMessage = { [weak self] message in
            DispatchQueue.main.async {
                self?.statusMessage = message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self?.statusMessage == message {
                        self?.statusMessage = nil
                    }
                }
            }
        }
    }

    func initialize() async {
        await manager.configureSession()
    }

    func toggleFlash() {
        manager.toggleFlash()
        isFlashEnabled = manager.isFlashEnabled
    }

    func switchCamera() {
        manager.switchCamera()
    }

    func setZoom(_ scale: CGFloat) {
        manager.setZoom(factor: scale)
        currentZoom = manager.currentZoomFactor
    }

    func focus(at point: CGPoint) {
        let screen = UIScreen.main.bounds.size
        manager.focus(at: point, in: screen)
    }

    func toggleVideoMode() {
        if isRecording {
            manager.stopRecording()
            isRecording = false
        }
        isVideoMode.toggle()
    }

    func capture() {
        if isVideoMode {
            if isRecording {
                manager.stopRecording()
            } else {
                manager.startRecording()
            }
            isRecording.toggle()
        } else {
            manager.capturePhoto(delegate: self)
        }
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput,
                                 didFinishProcessingPhoto photo: AVCapturePhoto,
                                 error: Error?) {
        if let error {
            Task { @MainActor in
                self.statusMessage = "Photo error: \(error.localizedDescription)"
            }
            return
        }

        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            Task { @MainActor in
                self.statusMessage = "Failed to process photo"
            }
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        Task { @MainActor in
            self.statusMessage = "Photo saved"
        }
    }
}
