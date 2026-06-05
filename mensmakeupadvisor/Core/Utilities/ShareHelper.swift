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

        // Archive 詳細などシート内から共有する場合、root は既にシートを
        // モーダル表示済みなので root.present は無言で失敗する。
        // 最前面の presentedViewController まで辿ってから present する。
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let pop = vc.popoverPresentationController {
            pop.sourceView = presenter.view
            pop.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0, height: 0
            )
            pop.permittedArrowDirections = []
        }
        presenter.present(vc, animated: true)
    }
}
