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
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .aid("onboarding_compare_slider")
        }
        .padding(.top, 16)
    }
}

struct BeforeAfterSlider: View {
    @Binding var sliderX: CGFloat

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let splitX = w * sliderX

            ZStack(alignment: .leading) {
                beforeSide(w: w, h: h)
                afterSide(w: w, h: h, splitX: splitX)
                dragHandle(h: h, splitX: splitX)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        sliderX = max(0, min(1, value.location.x / w))
                    }
            )
        }
    }

    private func beforeSide(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            if let img = UIImage(named: "sample_face") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .saturation(0.25)
                    .brightness(-0.08)
                    .clipped()
            } else {
                Rectangle().fill(Color(white: 0.18))
            }
            VStack {
                Spacer()
                HStack {
                    Text("BEFORE")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(2)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                    Spacer()
                }
            }
            .padding(8)
        }
    }

    private func afterSide(w: CGFloat, h: CGFloat, splitX: CGFloat) -> some View {
        ZStack {
            if let img = UIImage(named: "sample_face") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: w, height: h)
                    .brightness(0.05)
                    .clipped()
            } else {
                Rectangle().fill(Color(white: 0.26))
            }
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("AFTER")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(Color.ivory.opacity(0.8))
                        .kerning(2)
                        .padding(6)
                        .background(Color.black.opacity(0.5))
                }
            }
            .padding(8)
        }
        .frame(width: w - splitX)
        .offset(x: splitX)
    }

    private func dragHandle(h: CGFloat, splitX: CGFloat) -> some View {
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
        .offset(x: splitX - 14)
    }
}
