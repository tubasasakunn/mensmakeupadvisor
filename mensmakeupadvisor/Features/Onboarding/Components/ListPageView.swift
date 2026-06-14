import SwiftUI

struct ListPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.titleLBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            if let items = page.listItems {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    ForEach(items.indices, id: \.self) { i in
                        NumberedListItem(
                            number: String(format: "%02d", i + 1),
                            title: items[i].title,
                            desc: items[i].desc
                        )
                    }
                }
            }
        }
        .padding(.top, Theme.Spacing.lg)
    }
}

struct NumberedListItem: View {
    let number: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Text(number)
                .font(Theme.Typography.Data.base)
                .foregroundStyle(Color.brandPrimary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.UI.calloutSemibold)
                    .foregroundStyle(Color.ivory)

                Text(desc)
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
            }
        }
    }
}
