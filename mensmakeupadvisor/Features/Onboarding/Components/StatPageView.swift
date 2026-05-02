import SwiftUI

struct StatPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 32)

            Text(page.tag)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)
                .padding(.bottom, 31)

            if let stat = page.stat {
                Text(stat)
                    .font(.system(size: 88, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.bottom, 10)
            }

            if let label = page.statLabel {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ivory.opacity(0.85))
                    .lineSpacing(5)
                    .padding(.bottom, 26)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 21)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, 16)
            }

            if let source = page.source {
                Text(source)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary.opacity(0.6))
                    .kerning(0.5)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}
