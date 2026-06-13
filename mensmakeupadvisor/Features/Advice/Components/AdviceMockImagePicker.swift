import SwiftUI
import UIKit

struct AdviceMockImagePicker: View {
    let onSelect: (UIImage) -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Button("画像 \(index + 1)") {
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
                        let image = renderer.image { ctx in
                            let hue = CGFloat(index) / 3.0
                            UIColor(hue: hue, saturation: 0.3, brightness: 0.4, alpha: 1).setFill()
                            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
                        }
                        onSelect(image)
                    }
                    .font(Theme.Typography.Data.mediumMedium)
                    .foregroundStyle(Color.ivory)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.Surface.panelRaised, in: .capsule)
                    .overlay(
                        Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
                    )
                    .aid("advice_mock_image_\(index)")
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Theme.Typography.UI.caption)
                Text("MOCK MODE")
                    .font(Theme.Typography.Data.smallMedium)
                    .kerning(2)
            }
            .foregroundStyle(Theme.Status.warning)
        }
        .padding(Theme.Spacing.md)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.md)
                .stroke(Theme.Status.warningBorder, lineWidth: Theme.Size.Line.regular)
        )
        .aid("advice_mock_image_picker")
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        AdviceMockImagePicker { _ in }
            .padding(24)
    }
}
