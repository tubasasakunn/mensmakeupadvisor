import SwiftUI
import UIKit

struct DiagnosisSharePrompt: View {
    let result: AnalysisResult
    let capturedImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        Button {
            Task { await shareResult() }
        } label: {
            HStack(spacing: Theme.Spacing.lg) {
                miniCardPreview
                    .frame(width: 68, height: 88)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("結果をシェアする")
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)
                    Text("素顔のスコア — あなたは何点？")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Text.primaryFaded)
                }

                Spacer()

                if isRendering {
                    ProgressView().tint(result.gradeColor).scaleEffect(0.7)
                        .frame(width: 40, height: 40)
                } else {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.ivory)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(result.gradeColor.opacity(0.85))
                        )
                        .glassEffect(.regular, in: .circle)
                }
            }
            .padding(Theme.Spacing.md)
            .glassEffect(.regular, in: .rect(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(result.gradeColor.opacity(0.5), lineWidth: 0.8)
            )
        }
        .aid("diagnosis_share_button")
        .disabled(isRendering)
    }

    private var miniCardPreview: some View {
        ZStack {
            Theme.Surface.raised

            VStack(spacing: 0) {
                Text("M·M·A")
                    .font(.system(size: 5, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(result.totalScore)")
                        .font(.system(size: 20, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)
                    Spacer()
                    Text(result.grade)
                        .font(.system(size: 14, weight: .black, design: .serif))
                        .italic()
                        .foregroundStyle(result.gradeColor)
                }
                .padding(.horizontal, 6)

                HairlineDivider(height: 0.5)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)

                Text(result.faceShape.label)
                    .font(.system(size: 7, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .hairlineBorder(Color.lineStrong, cornerRadius: 2, lineWidth: 0.5)
    }

    private func shareResult() async {
        isRendering = true
        defer { isRendering = false }
        let card = DiagnosisShareCardView(result: result, capturedImage: capturedImage)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }
}

#Preview {
    DiagnosisSharePrompt(result: .mock, capturedImage: nil)
        .padding(24)
        .background(Color.appBackground)
}
