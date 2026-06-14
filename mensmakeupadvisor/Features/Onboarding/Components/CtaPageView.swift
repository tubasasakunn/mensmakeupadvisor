import SwiftUI

struct CtaPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("And so, we begin.")
                .font(Theme.Typography.Display.footnoteLight)
                .italic()
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
                .padding(.bottom, 24)

            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.heroLBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            HairlineDivider()
                .padding(.bottom, Theme.Spacing.lg)

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.body)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 24)
    }
}
