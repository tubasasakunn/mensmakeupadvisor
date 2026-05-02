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
            HStack(spacing: 14) {
                miniCardPreview
                    .frame(width: 68, height: 88)

                VStack(alignment: .leading, spacing: 3) {
                    Text("SHARE RESULT")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .kerning(1.5)
                        .foregroundStyle(Color.ivory)
                    Text("メイク前の素顔スコア — あなたは何点？")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.inkSecondary)
                }

                Spacer()

                if isRendering {
                    ProgressView().tint(result.gradeColor).scaleEffect(0.7)
                        .frame(width: 36, height: 36)
                } else {
                    Image(systemName: "arrow.up.forward")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.appBackground)
                        .frame(width: 36, height: 36)
                        .background(result.gradeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            .padding(14)
            .overlay(RoundedRectangle(cornerRadius: 2).stroke(result.gradeColor.opacity(0.5), lineWidth: 1))
        }
        .aid("diagnosis_share_button")
        .disabled(isRendering)
    }

    private var miniCardPreview: some View {
        ZStack {
            Color(white: 0.11)

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

                Rectangle().fill(Color.lineColor).frame(height: 0.5)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)

                Text(result.faceShape.label)
                    .font(.system(size: 7, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.lineStrong, lineWidth: 0.5))
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
