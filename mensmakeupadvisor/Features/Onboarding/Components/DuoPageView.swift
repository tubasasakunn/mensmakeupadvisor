import SwiftUI

struct DuoPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 20)

            HStack(alignment: .top, spacing: 16) {
                DuoColumn(
                    label: page.leftLabel ?? "",
                    labelJP: page.leftJP ?? "",
                    desc: page.leftDesc ?? "",
                    accentColor: Color.ivory
                )

                Rectangle()
                    .fill(Color.lineColor)
                    .frame(width: 1)
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
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(accentColor)

            Text(labelJP)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(accentColor.opacity(0.7))
                .kerning(0.5)
                .lineSpacing(3)

            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 1)

            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
