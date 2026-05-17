import SwiftUI

struct TutorialStepInfoArea: View {
    let currentStep: TutorialStep
    @Binding var intensity: MakeupIntensity
    @Binding var showBeforeImage: Bool
    @Binding var eyebrowType: EyebrowApplier.BrowType?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text("ACT \(currentStep.tag)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                Text("\(currentStep.label).")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }
            .aid("tutorial_step_info")

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.vertical, 14)

            Text(currentStep.desc)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // 眉ステップだけは type picker、それ以外は intensity slider
            Group {
                if currentStep.layer == .eyebrow {
                    eyebrowTypePicker
                } else {
                    intensitySlider
                }
            }
            .padding(.top, 20)

            beforeButton
                .padding(.top, 16)
        }
    }

    private var intensitySlider: some View {
        let layer = currentStep.layer
        let intensityValue = intensity[layer]
        let binding = Binding<Double>(
            get: { intensity[layer] },
            set: { intensity[layer] = $0 }
        )

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("INTENSITY")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)

                Text(String(format: "%.0f", intensityValue))
                    .font(.system(size: 36, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
            }

            CustomIntensitySlider(
                value: binding,
                range: 0...100
            )
            .aid("tutorial_intensity_slider")

            HStack {
                Text("OFF")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("· 50 ·")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                Spacer()
                Text("MAX")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var eyebrowTypePicker: some View {
        let options: [(label: String, value: EyebrowApplier.BrowType?)] = [
            ("OFF", nil),
            ("NATURAL", .natural),
            ("STRAIGHT", .straight),
            ("ARCH", .arch),
            ("PARALLEL", .parallel),
            ("CORNER", .corner),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            Text("BROW TYPE")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in browButton(options[i]) }
                }
                HStack(spacing: 6) {
                    ForEach(3..<6, id: \.self) { i in browButton(options[i]) }
                }
            }
        }
        .aid("tutorial_brow_type_picker")
    }

    private func browButton(_ entry: (label: String, value: EyebrowApplier.BrowType?)) -> some View {
        let isActive = (entry.value == eyebrowType)
        let aidValue = entry.value?.rawValue ?? "off"
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { eyebrowType = entry.value }
        } label: {
            Text(entry.label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .kerning(1.2)
                .foregroundStyle(isActive ? Color.appBackground : Color.ivory)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isActive ? Color.ivory : Color.clear)
                .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        }
        .aid("tutorial_brow_type_\(aidValue)")
    }

    private var beforeButton: some View {
        Button {
            // ロングプレス想定だが、タップトグルで代替
        } label: {
            Text("HOLD → BEFORE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(showBeforeImage ? Color.appBackground : Color.ivory)
                .kerning(1.5)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(showBeforeImage ? Color.ivory : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.lineStrong, lineWidth: 1)
                )
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.1)
                .onChanged { _ in showBeforeImage = true }
                .onEnded { _ in showBeforeImage = false }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in showBeforeImage = false }
        )
        .aid("tutorial_before_button")
    }
}

#Preview {
    @Previewable @State var intensity = MakeupIntensity()
    @Previewable @State var showBefore = false
    @Previewable @State var browType: EyebrowApplier.BrowType? = .natural
    TutorialStepInfoArea(
        currentStep: TutorialStep.all[0],
        intensity: $intensity,
        showBeforeImage: $showBefore,
        eyebrowType: $browType
    )
    .padding(28)
    .background(Color.appBackground)
}
