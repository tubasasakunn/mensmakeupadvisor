import SwiftUI

struct GoalPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.titleLBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            goalIconRow
                .padding(.bottom, Theme.Spacing.xl)

            if let quote = page.quote {
                HStack(alignment: .top, spacing: 14) {
                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: Theme.Size.Stroke.bold)

                    Text(quote)
                        .font(Theme.Typography.Display.calloutMedium)
                        .italic()
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, Theme.Spacing.lg)
            }

            HairlineDivider()
                .padding(.bottom, 14)

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.callout)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private var goalIconRow: some View {
        HStack(spacing: 0) {
            Spacer()
            goalIconItem(symbol: "moon.zzz.fill",    label: "よく寝た翌朝")
            Spacer()
            goalIconItem(symbol: "sun.horizon.fill",  label: "肌の調子がいい")
            Spacer()
            goalIconItem(symbol: "face.smiling.fill", label: "あの顔")
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.lg)
        .background(Theme.Surface.glassWeak)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private func goalIconItem(symbol: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: symbol)
                .font(Theme.Typography.UI.titleLarge)
                .foregroundStyle(Theme.Accent.primaryFaded)
                .frame(width: Theme.Size.Control.circleXLarge, height: Theme.Size.Control.circleXLarge)
                .background(Theme.Surface.glassWeak)
                .clipShape(Circle())

            Text(label)
                .font(Theme.Typography.Data.base)
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
        }
    }
}
