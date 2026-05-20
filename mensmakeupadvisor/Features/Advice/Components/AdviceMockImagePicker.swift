import SwiftUI
import UIKit

struct AdviceMockImagePicker: View {
    let onSelect: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Button("画像\(index + 1)") {
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
                        let image = renderer.image { ctx in
                            let hue = CGFloat(index) / 3.0
                            UIColor(hue: hue, saturation: 0.3, brightness: 0.4, alpha: 1).setFill()
                            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
                        }
                        onSelect(image)
                    }
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.ivory)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.Surface.glassMedium)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .aid("advice_mock_image_\(index)")
                }
            }

            Text("[MOCK] 画像ピッカー")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.Status.warning)
        }
        .padding(12)
        .hairlineBorder(Theme.Status.warningBorder, cornerRadius: 4)
        .aid("advice_mock_image_picker")
    }
}

#Preview {
    AdviceMockImagePicker { _ in }
        .padding(24)
        .background(Color.appBackground)
}
