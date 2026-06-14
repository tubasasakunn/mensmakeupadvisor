import SwiftUI

struct StatPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 32)

            Text(page.tag)
                .font(Theme.Typography.Data.baseRegular)
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)
                .padding(.bottom, 31)

            if let stat = page.stat {
                Text(stat)
                    .font(Theme.Typography.Display.colossalXLBold)
                    .foregroundStyle(Color.ivory)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.bottom, 10)
            }

            if let label = page.statLabel {
                Text(label)
                    .font(Theme.Typography.UI.headlineMedium)
                    .foregroundStyle(Theme.Plate.renderingTint)
                    .lineSpacing(5)
                    .padding(.bottom, 26)
            }

            HairlineDivider()
                .padding(.bottom, 21)

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.bodyLargeRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, Theme.Spacing.lg)
            }

            if let source = page.source {
                Text(source)
                    .font(Theme.Typography.Data.base)
                    .foregroundStyle(Theme.Text.secondaryDim)
                    .kerning(0.5)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, Theme.Spacing.lg)
    }
}
