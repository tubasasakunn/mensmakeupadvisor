import SwiftUI

struct CtaPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("And so, we begin.")
                .font(.system(size: 13, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
                .padding(.bottom, 24)

            if let title = page.title {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 24)
    }
}
