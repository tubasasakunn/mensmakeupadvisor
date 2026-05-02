import SwiftUI

struct FeaturePageView: View {
    let page: OnboardingPage

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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .kerning(1.5)
                    }
                }

                Spacer()

                FaceDiagramView(
                    region: regionKey,
                    caption: "FIG. \(page.featureLabel?.uppercased() ?? "")"
                )
            }
            .padding(.bottom, 16)

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
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
            }
        }
        .padding(.top, 16)
    }
}
