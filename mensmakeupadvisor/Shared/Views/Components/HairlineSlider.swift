import SwiftUI

// editorial 雰囲気のミニマル横線スライダー。トラックは 1pt の罫線、
// サムは縦長の薄い矩形。Tutorial の "強さ" や Studio の FineTune で使う。
//
// 以前は CustomIntensitySlider と StudioSlider に分かれていたが、差分は
// サム寸法と進捗色だけだったので Style パラメータで吸収して 1 本化した。
struct HairlineSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    var style: Style = .tutorial

    struct Style {
        let handleWidth: CGFloat
        let handleHeight: CGFloat
        let progressColor: Color

        static let tutorial = Style(
            handleWidth: 8,
            handleHeight: 16,
            progressColor: Theme.Step.labelTag
        )

        static let studio = Style(
            handleWidth: 6,
            handleHeight: 14,
            progressColor: Theme.Step.baseDot
        )
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let handleX = fraction * width

            ZStack(alignment: .leading) {
                HairlineDivider()

                Rectangle()
                    .fill(style.progressColor)
                    .frame(width: handleX, height: 1)

                Rectangle()
                    .fill(Color.ivory)
                    .frame(width: style.handleWidth, height: style.handleHeight)
                    .offset(x: handleX - style.handleWidth / 2)
            }
            .contentShape(Rectangle().size(CGSize(width: width, height: 44)).offset(y: -22))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let fraction = (drag.location.x / width).clamped(to: 0...1)
                        value = range.lowerBound + fraction * (range.upperBound - range.lowerBound)
                    }
            )
        }
        .frame(height: style.handleHeight)
    }
}

#Preview {
    @Previewable @State var v1: Double = 50
    @Previewable @State var v2: Double = 35
    return VStack(spacing: 32) {
        HairlineSlider(value: $v1, range: 0...100, style: .tutorial)
        HairlineSlider(value: $v2, range: 0...100, style: .studio)
    }
    .padding(24)
    .background(Color.appBackground)
}
