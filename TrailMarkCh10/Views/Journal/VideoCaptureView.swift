//
//  VideoCaptureView.swift
//  TrailMarkCh10
//
//  Created by Lemuel Gayle on 9/12/26.
//

import SwiftUI
import AVFoundation
import UIKit
import UniformTypeIdentifiers

struct VideoCaptureView: UIViewControllerRepresentable {
    let onCapture: (URL, TimeInterval) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = [UTType.movie.identifier]
        picker.videoQuality = .typeMedium

        if picker.sourceType == .camera {
            picker.cameraCaptureMode = .video
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (URL, TimeInterval) -> Void

        init(onCapture: @escaping (URL, TimeInterval) -> Void) {
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            guard let url = info[.mediaURL] as? URL else { return }

            Task {
                let asset = AVURLAsset(url: url)
                let duration = try? await asset.load(.duration)
                let seconds = duration.map(CMTimeGetSeconds) ?? 0

                await MainActor.run {
                    onCapture(url, seconds.isFinite ? seconds : 0)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
