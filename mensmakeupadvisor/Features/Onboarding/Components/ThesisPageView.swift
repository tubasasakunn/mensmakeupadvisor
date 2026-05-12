import SwiftUI

struct ThesisPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The Thesis.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
                .padding(.bottom, 20)

            if let title = page.title {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 16)
            }

            // Text の結合は foregroundStyle が使えないため foregroundColor を用いる（Text API の制約）
            buildCompositeText()
                .font(.system(size: 22, weight: .regular, design: .serif))
                .lineSpacing(12)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }

    private func buildCompositeText() -> Text {
        // iOS 26 で Text + Text が deprecated になったため AttributedString で組み立て、
        // 最後に Text(AttributedString) に渡す。
        var combined = AttributedString("")
        func append(_ s: String, color: Color, bold: Bool = false) {
            var seg = AttributedString(s)
            seg.foregroundColor = color
            if bold { seg.font = .system(size: 22, weight: .bold, design: .serif) }
            combined.append(seg)
        }
        if let b1 = page.body1 { append(b1, color: .ivory) }
        if let hl = page.highlight { append(hl, color: .brandPrimary, bold: true) }
        if let b2 = page.body2 { append(b2, color: .ivory) }
        if let b3 = page.body3 {
            combined.append(AttributedString("\n"))
            append(b3, color: .brandPrimary, bold: true)
        }
        if let b4 = page.body4 { append(b4, color: .ivory) }
        if let b5 = page.body5 {
            combined.append(AttributedString("\n"))
            append(b5, color: .ivory)
        }
        return Text(combined)
    }
}
