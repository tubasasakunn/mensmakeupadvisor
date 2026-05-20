import SwiftUI

extension View {
    // 直角の罫線枠。`.overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))`
    // をアプリ全体で書き散らしていたのを集約する。
    func hairlineBorder(
        _ color: Color = Color.lineColor,
        lineWidth: CGFloat = 1
    ) -> some View {
        overlay(Rectangle().stroke(color, lineWidth: lineWidth))
    }

    // 角丸の罫線枠。Onboarding のボタンや Advice のセカンダリ要素で多用。
    func hairlineBorder(
        _ color: Color = Color.lineColor,
        cornerRadius: CGFloat,
        lineWidth: CGFloat = 1
    ) -> some View {
        overlay(RoundedRectangle(cornerRadius: cornerRadius).stroke(color, lineWidth: lineWidth))
    }
}
