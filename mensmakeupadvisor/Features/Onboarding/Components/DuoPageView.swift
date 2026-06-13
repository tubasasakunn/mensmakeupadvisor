import SwiftUI

struct DuoPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HairlineDivider()
                .padding(.bottom, 20)

            HStack(alignment: .top, spacing: 16) {
                DuoColumn(
                    label: page.leftLabel ?? "",
                    labelJP: page.leftJP ?? "",
                    desc: page.leftDesc ?? "",
                    accentColor: Color.ivory
                )

                HairlineVDivider()
                    .frame(maxHeight: .infinity)

                DuoColumn(
                    label: page.rightLabel ?? "",
                    labelJP: page.rightJP ?? "",
                    desc: page.rightDesc ?? "",
                    accentColor: Color.inkSecondary
                )
            }
        }
        .padding(.top, 16)
    }
}

struct DuoColumn: View {
    let label: String
    let labelJP: String
    let desc: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.Typography.Display.displayLBold)
                .italic()
                .foregroundStyle(accentColor)

            Text(labelJP)
                .font(Theme.Typography.Data.base)
                .foregroundStyle(accentColor.opacity(0.7))
                .kerning(0.5)
                .lineSpacing(3)

            HairlineDivider(color: accentColor.opacity(0.3))

            Text(desc)
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
