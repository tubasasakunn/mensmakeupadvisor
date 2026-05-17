import SwiftUI

// FineTune の intensity 用ミニマル横線スライダー。
// SwiftUI 標準 Slider は太い縦サムなので editorial 雰囲気を出すために自作。
struct StudioSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let handleX = fraction * width

            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)

                Rectangle()
                    .fill(Color.ivory.opacity(0.5))
                    .frame(width: handleX, height: 1)

                Rectangle()
                    .fill(Color.ivory)
                    .frame(width: 6, height: 14)
                    .offset(x: handleX - 3)
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
        .frame(height: 14)
    }
}
