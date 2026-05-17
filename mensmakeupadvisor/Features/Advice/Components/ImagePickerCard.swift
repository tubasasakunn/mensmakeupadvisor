import SwiftUI
import UIKit

// MARK: - UIImagePickerController (Camera) Representable

// 撮影専用。シミュレータではカメラが使えないので、その場合はライブラリ
// フォールバック (photoLibrary) で代替する。
struct CameraCaptureView: UIViewControllerRepresentable {
    let onCapture: @MainActor (UIImage) -> Void
    let onCancel: @MainActor () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.cameraDevice = .front
            picker.cameraCaptureMode = .photo
        } else {
            // シミュレータなど実機カメラがない環境向けフォールバック
            picker.sourceType = .photoLibrary
        }
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onCapture: @MainActor (UIImage) -> Void
        private let onCancel: @MainActor () -> Void

        init(onCapture: @MainActor @escaping (UIImage) -> Void,
             onCancel: @MainActor @escaping () -> Void) {
            self.onCapture = onCapture
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            Task { @MainActor in
                picker.dismiss(animated: true) {
                    if let image {
                        self.onCapture(image)
                    } else {
                        self.onCancel()
                    }
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            Task { @MainActor in
                picker.dismiss(animated: true) {
                    self.onCancel()
                }
            }
        }
    }
}
