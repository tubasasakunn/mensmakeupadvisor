import SwiftUI

struct ExamplePageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.titleLBold)
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            if let items = page.exampleItems {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(items.indices, id: \.self) { i in
                        ExampleItemView(
                            concern: items[i].concern,
                            advice: items[i].advice
                        )
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity)
    }
}

struct ExampleItemView: View {
    let concern: String
    let advice: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Text("Q")
                    .font(Theme.Typography.Data.base)
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 2)
                Text(concern)
                    .font(Theme.Typography.UI.calloutMedium)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Text("→")
                    .font(Theme.Typography.Data.base)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 2)
                Text(advice)
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Theme.Surface.glassWeakIvory)
        .hairlineBorder(cornerRadius: 6)
    }
}
