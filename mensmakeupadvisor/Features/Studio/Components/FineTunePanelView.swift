import SwiftUI

struct FineTunePanelView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("FINE TUNE")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
                .padding(.bottom, 16)

            VStack(spacing: 20) {
                ForEach(MakeupLayer.allCases, id: \.self) { layer in
                    layerSliderRow(layer)
                }
            }
        }
    }

    private func layerSliderRow(_ layer: MakeupLayer) -> some View {
        let value = appState.intensity[layer]

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .lastTextBaseline) {
                Text(layer.label.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                    .frame(width: 70, alignment: .leading)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .frame(width: 36, alignment: .trailing)
            }

            StudioSlider(
                value: Binding(
                    get: { appState.intensity[layer] },
                    set: { appState.intensity[layer] = $0 }
                ),
                range: 0...100
            )
            .aid("studio_intensity_\(layer.rawValue)")
        }
    }
}

// MARK: - Studio Slider

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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        Swift.max(range.lowerBound, Swift.min(range.upperBound, self))
    }
}

#Preview {
    FineTunePanelView()
        .environment(AppState())
        .padding()
        .background(Color.appBackground)
}
