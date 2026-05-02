import SwiftUI

struct GoalPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            if let quote = page.quote {
                HStack(alignment: .top, spacing: 14) {
                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: 3)

                    Text(quote)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(6)
                }
                .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}
