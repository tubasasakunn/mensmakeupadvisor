import SwiftUI
import UIKit

private enum Layout {
    nonisolated static let sliderHeight: CGFloat = 260
}

struct ComparePageView: View {
    let page: OnboardingPage
    @State private var sliderX: CGFloat = 0.5

    private let beforeImage = UIImage(named: "onboarding_face_before") ?? UIImage(named: "sample_face")
    private let afterImage  = UIImage(named: "onboarding_face_after")  ?? UIImage(named: "sample_face")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.displayBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, Theme.Spacing.md)
            }

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.callout)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .padding(.bottom, Theme.Spacing.xl)
            }

            BeforeAfterSlider(
                sliderX: $sliderX,
                beforeImage: beforeImage,
                afterImage: afterImage,
                style: .standard
            )
            .frame(height: Layout.sliderHeight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aid("onboarding_compare_slider")
        }
        .padding(.top, Theme.Spacing.lg)
    }
}
