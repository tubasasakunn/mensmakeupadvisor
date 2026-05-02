import SwiftUI

struct CoverPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let no = page.chapterNo {
                Text(no)
                    .font(.system(size: 88, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.bottom, 4)
            }

            if let title = page.title {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .serif))
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

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 24)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}
