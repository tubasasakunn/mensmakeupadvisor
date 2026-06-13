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
                    .font(Theme.Typography.Display.megaBold)
                    .italic()
                    .foregroundStyle(Theme.Accent.primarySubtle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .allowsTightening(true)
                    .padding(.bottom, -30)
            }

            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.displayBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 14)
            }

            HairlineDivider()
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
                    .font(Theme.Typography.UI.body)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 8)
    }
}
