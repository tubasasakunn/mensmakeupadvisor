import SwiftUI

struct HowtoPageView: View {
    let page: OnboardingPage

    private var animatedStep: String? {
        guard let step = page.step,
              HowtoAnimationView.hasAnimation(for: step) else { return nil }
        return step
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let step = page.step {
                Text(step)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary.opacity(0.28))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .allowsTightening(true)
                    .padding(.bottom, -30)
            }

            if let title = page.title {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 14)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let step = animatedStep {
                HowtoAnimationView(step: step)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 260)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 16)
            }

            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 8)
    }
}
