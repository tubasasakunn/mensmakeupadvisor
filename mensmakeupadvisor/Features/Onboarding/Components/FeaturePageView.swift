import SwiftUI
import UIKit

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
                            .font(.system(size: 10, design: .monospaced))
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
                StepBeforeAfterSlider(
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    label: page.featureLabel ?? ""
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.bottom, 14)
            }

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
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - StepBeforeAfterSlider

struct StepBeforeAfterSlider: View {
    let beforeImage: UIImage?
    let afterImage: UIImage?
    let label: String
    @State private var sliderX: CGFloat = 0.5

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .leading) {
                // After — 底レイヤー: 常に full size で固定
                stepImageLayer(img: afterImage, w: w, h: h, placeholder: Color(white: 0.22))
                    .overlay(alignment: .bottomTrailing) {
                        stepBadge("AFTER", color: Color.ivory.opacity(0.9))
                    }

                // Before — 上レイヤー: full size だが左端からクリップ
                stepImageLayer(img: beforeImage, w: w, h: h, placeholder: Color(white: 0.15))
                    .overlay(alignment: .bottomLeading) {
                        stepBadge("BEFORE", color: Color.inkSecondary)
                    }
                    .clipShape(StepRevealShape(fraction: sliderX))

                // ハンドル
                ZStack {
                    Rectangle()
                        .fill(Color.ivory.opacity(0.9))
                        .frame(width: 2)
                    Circle()
                        .fill(Color.ivory)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.appBackground)
                        )
                }
                .frame(height: h)
                .offset(x: w * sliderX - 13)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sliderX = max(0, min(1, value.location.x / w))
                    }
            )
        }
    }

    private func stepImageLayer(img: UIImage?, w: CGFloat, h: CGFloat, placeholder: Color) -> some View {
        Group {
            if let img {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .clipped()
            } else {
                placeholder.frame(width: w, height: h)
            }
        }
    }

    private func stepBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(color)
            .kerning(2)
            .padding(6)
            .background(Color.black.opacity(0.5))
            .padding(8)
    }
}

private struct StepRevealShape: Shape {
    var fraction: CGFloat
    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: rect.width * fraction, height: rect.height))
    }
}
