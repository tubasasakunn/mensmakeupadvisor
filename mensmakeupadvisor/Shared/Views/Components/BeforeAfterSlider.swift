import SwiftUI
import UIKit

// before/after 画像の左右ドラッグ比較ビュー。
// Onboarding の Compare ページ・Feature ページの step 紹介から呼ばれる。
//
// 以前は ComparePageView 内に BeforeAfterSlider、FeaturePageView 内に
// StepBeforeAfterSlider と同じ構造のものが 2 つあったので統合した。差分は
// ハンドル寸法 / badge 色 / placeholder 色だけだったので Style で吸収。
struct BeforeAfterSlider: View {
    @Binding var sliderX: CGFloat
    let beforeImage: UIImage?
    let afterImage: UIImage?
    var style: Style = .standard
    var beforeLabel: String = "BEFORE"
    var afterLabel: String = "AFTER"

    struct Style {
        let handleSize: CGFloat
        let beforePlaceholder: Color
        let afterPlaceholder: Color
        let afterBadgeColor: Color

        static let standard = Style(
            handleSize: 28,
            beforePlaceholder: Theme.Placeholder.stepBeforeMed,
            afterPlaceholder: Theme.Placeholder.stepAfterMed,
            afterBadgeColor: Theme.Plate.beforeAfterDivider
        )

        static let step = Style(
            handleSize: 26,
            beforePlaceholder: Theme.Placeholder.stepBeforeSoft,
            afterPlaceholder: Theme.Placeholder.stepAfterSoft,
            afterBadgeColor: Theme.Plate.labelText
        )
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .leading) {
                imageLayer(img: afterImage, w: w, h: h, placeholder: style.afterPlaceholder)
                    .overlay(alignment: .bottomTrailing) {
                        badge(afterLabel, color: style.afterBadgeColor)
                    }

                imageLayer(img: beforeImage, w: w, h: h, placeholder: style.beforePlaceholder)
                    .overlay(alignment: .bottomLeading) {
                        badge(beforeLabel, color: Color.inkSecondary)
                    }
                    .clipShape(SliderRevealShape(fraction: sliderX))

                dragHandle(h: h, x: w * sliderX)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sliderX = (value.location.x / w).clamped(to: 0...1)
                    }
            )
        }
    }

    private func imageLayer(img: UIImage?, w: CGFloat, h: CGFloat, placeholder: Color) -> some View {
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

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(Theme.Typography.Data.base)
            .foregroundStyle(color)
            .kerning(2)
            .padding(6)
            .background(Theme.Surface.scrim)
            .padding(8)
    }

    private func dragHandle(h: CGFloat, x: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Theme.Plate.labelText)
                .frame(width: Theme.Size.Stroke.regular)
            Circle()
                .fill(Color.ivory)
                .frame(width: style.handleSize, height: style.handleSize)
                .overlay(
                    Image(systemName: "arrow.left.arrow.right")
                        .font(Theme.Typography.UI.footnoteBold)
                        .foregroundStyle(Color.appBackground)
                )
        }
        .frame(height: h)
        .offset(x: x - style.handleSize / 2)
    }
}

// Before 側を左端から fraction 分だけ表示するクリップシェイプ。
private struct SliderRevealShape: Shape {
    var fraction: CGFloat
    var animatableData: CGFloat {
        get { fraction }
        set { fraction = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: rect.width * fraction, height: rect.height))
    }
}
