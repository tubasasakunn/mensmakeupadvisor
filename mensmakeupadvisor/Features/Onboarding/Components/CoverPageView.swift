import SwiftUI

struct CoverPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let no = page.chapterNo {
                Text(no)
                    .font(Theme.Typography.Display.colossalXLBold)
                    .italic()
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.bottom, 4)
            }

            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.heroBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 16)
            }

            if let sub = page.subtitle {
                Text(sub)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
                    .padding(.bottom, 24)
            }

            HairlineDivider()
                .padding(.bottom, 24)

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.bodyLargeRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}
