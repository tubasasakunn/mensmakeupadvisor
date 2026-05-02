import SwiftUI

extension View {
    func editorialCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }

    func kbdStyle() -> some View {
        self
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .tracking(2)
            .textCase(.uppercase)
    }

    func editorialDivider() -> some View {
        self.overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
        }
    }
}

extension Text {
    func kbdStyle() -> Text {
        self
            .font(.system(.caption2, design: .monospaced))
            .foregroundColor(Color.inkSecondary)
    }
}
