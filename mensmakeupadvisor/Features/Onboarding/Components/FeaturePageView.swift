import SwiftUI
import UIKit

struct FeaturePageView: View {
    let page: OnboardingPage
    @State private var sliderX: CGFloat = 0.5

    private var regionKey: String {
        switch page.featureLabel {
        case "Base":      "base"
        case "Highlight": "highlight"
        case "Shadow":    "shadow"
        case "Eyes":      "eyes"
        case "Brows":     "brows"
        default:          "base"
        }
    }

    private var stepKey: String {
        switch page.featureLabel {
        case "Base":      "base"
        case "Highlight": "highlight"
        case "Shadow":    "shadow"
        case "Eyes":      "eye"
        case "Brows":     "brow"
        default:          "base"
        }
    }

    private var beforeImage: UIImage? { UIImage(named: "step_\(stepKey)_before") }
    private var afterImage:  UIImage? { UIImage(named: "step_\(stepKey)_after")  }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ラベル行
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    if let no = page.featureNo {
                        Text(no)
                            .font(.system(size: 52, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(Color.brandPrimary)
                    }
                    if let label = page.featureLabel {
                        Text(label)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.ivory)
                    }
                    if let jp = page.featureLabelJP {
                        Text(jp)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .kerning(1.5)
                    }
                }
                Spacer()
                // before/after 画像があれば使い、なければ線画
                if beforeImage == nil {
                    FaceDiagramView(
                        region: regionKey,
                        caption: "FIG. \(page.featureLabel?.uppercased() ?? "")"
                    )
                }
            }
            .padding(.bottom, 12)

            // before/after スライダー（画像がある場合のみ）
            if beforeImage != nil || afterImage != nil {
                BeforeAfterSlider(
                    sliderX: $sliderX,
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    style: .step
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 14)
            }

            HairlineDivider()
                .padding(.bottom, 14)

            if let title = page.title {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 10)
            }

            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 16)
    }
}
