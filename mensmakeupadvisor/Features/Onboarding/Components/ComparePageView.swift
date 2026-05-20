import SwiftUI
import UIKit

struct ComparePageView: View {
    let page: OnboardingPage
    @State private var sliderX: CGFloat = 0.5

    private let beforeImage = UIImage(named: "onboarding_face_before") ?? UIImage(named: "sample_face")
    private let afterImage  = UIImage(named: "onboarding_face_after")  ?? UIImage(named: "sample_face")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
            }

            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .padding(.bottom, 20)
            }

            BeforeAfterSlider(
                sliderX: $sliderX,
                beforeImage: beforeImage,
                afterImage: afterImage,
                style: .standard
            )
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .aid("onboarding_compare_slider")
        }
        .padding(.top, 16)
    }
}
