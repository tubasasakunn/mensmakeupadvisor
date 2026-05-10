import SwiftUI
import UIKit

struct ComparePageView: View {
    let page: OnboardingPage
    @State private var sliderX: CGFloat = 0.5

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

            BeforeAfterSlider(sliderX: $sliderX)
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .aid("onboarding_compare_slider")
        }
        .padding(.top, 16)
    }
}

struct BeforeAfterSlider: View {
    @Binding var sliderX: CGFloat

    private let beforeImage = UIImage(named: "onboarding_face_before") ?? UIImage(named: "sample_face")
    private let afterImage  = UIImage(named: "onboarding_face_after")  ?? UIImage(named: "sample_face")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .leading) {
                // After — 底レイヤー: 常に full size で固定
                sliderImageLayer(img: afterImage, w: w, h: h, placeholder: Color(white: 0.26))
                    .overlay(alignment: .bottomTrailing) {
                        sliderBadge("AFTER", color: Color.ivory.opacity(0.8))
                    }

                // Before — 上レイヤー: full size だが左端からクリップ
                sliderImageLayer(img: beforeImage, w: w, h: h, placeholder: Color(white: 0.18))
                    .overlay(alignment: .bottomLeading) {
                        sliderBadge("BEFORE", color: Color.inkSecondary)
                    }
                    .clipShape(SliderRevealShape(fraction: sliderX))

                dragHandle(h: h, x: w * sliderX)
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

    private func sliderImageLayer(img: UIImage?, w: CGFloat, h: CGFloat, placeholder: Color) -> some View {
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

    private func sliderBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, design: .monospaced))
            .foregroundStyle(color)
            .kerning(2)
            .padding(6)
            .background(Color.black.opacity(0.5))
            .padding(8)
    }

    private func dragHandle(h: CGFloat, x: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.ivory.opacity(0.9))
                .frame(width: 2)
            Circle()
                .fill(Color.ivory)
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.appBackground)
                )
        }
        .frame(height: h)
        .offset(x: x - 14)
    }
}

// Before 側を左端から fraction 分だけ表示するクリップシェイプ
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
