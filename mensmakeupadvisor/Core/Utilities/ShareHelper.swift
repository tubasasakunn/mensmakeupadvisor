import SwiftUI
import UIKit

@MainActor
enum ShareHelper {
    static func render<V: View>(_ view: V, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        return renderer.uiImage
    }

    static func present(_ items: [Any]) {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let rootVC = windowScene.keyWindow?.rootViewController
        else { return }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = rootVC.view
            pop.sourceRect = CGRect(
                x: rootVC.view.bounds.midX,
                y: rootVC.view.bounds.midY,
                width: 0, height: 0
            )
            pop.permittedArrowDirections = []
        }
        rootVC.present(vc, animated: true)
    }
}
