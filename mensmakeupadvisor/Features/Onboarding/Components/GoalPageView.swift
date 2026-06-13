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
                    .padding(.bottom, 20)
            }

            goalIconRow
                .padding(.bottom, 20)

            if let quote = page.quote {
                HStack(alignment: .top, spacing: 14) {
                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: 3)

                    Text(quote)
                        .font(Theme.Typography.Display.calloutMedium)
                        .italic()
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
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
        .padding(.top, 16)
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
        .padding(.vertical, 16)
        .background(Theme.Surface.glassWeak)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func goalIconItem(symbol: String, label: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(Theme.Typography.UI.titleLarge)
                .foregroundStyle(Theme.Accent.primaryFaded)
                .frame(width: 56, height: 56)
                .background(Theme.Surface.glassWeak)
                .clipShape(Circle())

            Text(label)
                .font(Theme.Typography.Data.base)
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
        }
    }
}
