import PhotosUI
import SwiftUI
import UIKit

// MARK: - PHPicker UIViewControllerRepresentable

struct ImagePickerView: UIViewControllerRepresentable {
    let onSelect: @MainActor (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    // NSObject ベース: PHPickerViewControllerDelegate は @MainActor 非分離のため
    // Task { @MainActor } でコールバックをメインスレッドに戻す。
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onSelect: @MainActor (UIImage) -> Void

        init(onSelect: @MainActor @escaping (UIImage) -> Void) {
            self.onSelect = onSelect
        }

        func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            Task { @MainActor in
                picker.dismiss(animated: true)
            }
            guard let result = results.first else { return }
            let provider = result.itemProvider
            guard provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                Task { @MainActor [weak self] in
                    self?.onSelect(image)
                }
            }
        }
    }
}
