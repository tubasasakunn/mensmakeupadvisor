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
        var result = Text("")
        if let b1 = page.body1 {
            result = result + Text(b1).foregroundColor(Color.ivory)
        }
        if let hl = page.highlight {
            result = result + Text(hl).foregroundColor(Color.brandPrimary).bold()
        }
        if let b2 = page.body2 {
            result = result + Text(b2).foregroundColor(Color.ivory)
        }
        if let b3 = page.body3 {
            result = result + Text("\n") + Text(b3).foregroundColor(Color.brandPrimary).bold()
        }
        if let b4 = page.body4 {
            result = result + Text(b4).foregroundColor(Color.ivory)
        }
        if let b5 = page.body5 {
            result = result + Text("\n") + Text(b5).foregroundColor(Color.ivory)
        }
        return result
    }
}
