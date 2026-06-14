import SwiftUI

struct ConceptPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let ct = page.conceptTitle {
                Text(ct)
                    .font(Theme.Typography.Display.jumboXLLight)
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, Theme.Spacing.xs)
            }

            if let jp = page.titleJP {
                Text(jp)
                    .font(Theme.Typography.Data.largeMedium)
                    .foregroundStyle(Color.brandPrimary)
                    .kerning(2)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            HairlineDivider()
                .padding(.bottom, Theme.Spacing.lg)

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.bodyLargeRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, Theme.Spacing.md)
            }

            if let source = page.source {
                Text(source)
                    .font(Theme.Typography.Data.base)
                    .foregroundStyle(Theme.Text.secondaryDim)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, Theme.Spacing.lg)
    }
}
