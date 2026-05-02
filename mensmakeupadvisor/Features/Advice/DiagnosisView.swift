import SwiftUI
import UIKit

// MARK: - DiagnosisView

struct DiagnosisView: View {
    @Environment(AppState.self) private var appState
    @State private var isRendering = false
    @State private var gradeBadgeVisible = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        reportHeader
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        titleBlock
                            .padding(.top, 12)
                            .padding(.horizontal, 24)

                        captionLine
                            .padding(.top, 8)
                            .padding(.horizontal, 24)

                        dividerLine
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        heroSection
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        // スコアを見た直後の「シェアしたい」瞬間に配置
                        sharePrompt
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        faceMeshPlate
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        dividerLine
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        scoreListSection
                            .padding(.top, 4)
                            .padding(.horizontal, 24)

                        bottomButtons
                            .padding(.top, 32)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 56)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .aid("diagnosis_view")
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        HStack {
            Button {
                appState.navigate(to: .capture)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                    Text("BACK")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .kerning(1.5)
                }
                .foregroundStyle(Color.inkSecondary)
            }
            .aid("diagnosis_back_button")

            Spacer()

            Text("DIAGNOSIS · REPORT")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
        }
    }

    // MARK: - Header

    private var reportHeader: some View {
        Text("CHAPTER 07 · RESULT")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("step two.")
                .font(.system(size: 38, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("診断結果.")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var captionLine: some View {
        Text("— a study of seven proportions —")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(1.5)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
    }

    // MARK: - Hero Section

    @ViewBuilder
    private var heroSection: some View {
        let result = appState.analysisResult ?? .mock

        HStack(alignment: .center, spacing: 24) {
            // グレードバッジをリングの右下に重ねる
            ZStack(alignment: .bottomTrailing) {
                ScoreRingView(value: result.totalScore, size: 160)
                    .aid("diagnosis_score_ring")

                Text(result.grade)
                    .font(.system(size: 17, weight: .black, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
                    .frame(width: 44, height: 44)
                    .background(result.gradeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: result.gradeColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    .offset(x: 8, y: 8)
                    .opacity(gradeBadgeVisible ? 1 : 0)
                    .scaleEffect(gradeBadgeVisible ? 1 : 0.4)
                    .onAppear {
                        withAnimation(.spring(duration: 0.5, bounce: 0.4).delay(1.5)) {
                            gradeBadgeVisible = true
                        }
                    }
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FACE SHAPE")
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(2)

                    Text(result.faceShape.label)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)

                    // グレード説明（バッジの意味を補足）
                    HStack(spacing: 5) {
                        Text(result.grade)
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundStyle(result.gradeColor)
                        Text("·")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                        Text(result.gradeDescription)
                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                            .foregroundStyle(result.gradeColor.opacity(0.9))
                            .kerning(0.5)
                    }

                    // ランクパーセンタイル（UGC動機付け）
                    Text(result.rankPercentile)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(1)
                }

                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)

                Text(result.faceShape.note)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var diagnosisResult: AnalysisResult {
        appState.analysisResult ?? .mock
    }

    // MARK: - Face Mesh Plate

    @ViewBuilder
    private var faceMeshPlate: some View {
        ZStack(alignment: .bottomLeading) {
            // 画像またはプレースホルダー
            Group {
                if let image = appState.capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.04))
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(Color.appBackground.opacity(0.45))
            .overlay(meshGridOverlay)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.lineColor, lineWidth: 1)
            )

            // FIG.01 ラベル
            VStack(alignment: .leading, spacing: 2) {
                Text("FIG. 01")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
                Text("FACE MESH")
                    .font(.system(size: 8, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.5)
            }
            .padding(12)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var meshGridOverlay: some View {
        Canvas { context, size in
            let cols = 10
            let rows = 12
            let cellW = size.width / CGFloat(cols)
            let cellH = size.height / CGFloat(rows)

            for col in 0...cols {
                var p = Path()
                let x = CGFloat(col) * cellW
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: .color(Color.ivory.opacity(0.06)), lineWidth: 0.5)
            }
            for row in 0...rows {
                var p = Path()
                let y = CGFloat(row) * cellH
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: .color(Color.ivory.opacity(0.06)), lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Score List

    @ViewBuilder
    private var scoreListSection: some View {
        let result = appState.analysisResult ?? .mock

        VStack(spacing: 0) {
            // 強み / 弱みサマリー
            if let best = result.strongestScore, let worst = result.weakestScore {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("STRONGEST")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                            .kerning(1.5)
                        HStack(spacing: 4) {
                            Text(best.name)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .italic()
                                .foregroundStyle(Color.ivory)
                            Text(best.grade)
                                .font(.system(size: 12, weight: .black, design: .serif))
                                .italic()
                                .foregroundStyle(best.gradeColor)
                        }
                    }

                    Spacer()

                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(width: 1, height: 36)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text("NEEDS CARE")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.inkTertiary)
                            .kerning(1.5)
                        HStack(spacing: 4) {
                            Text(worst.grade)
                                .font(.system(size: 12, weight: .black, design: .serif))
                                .italic()
                                .foregroundStyle(worst.gradeColor)
                            Text(worst.name)
                                .font(.system(size: 12, weight: .medium, design: .serif))
                                .italic()
                                .foregroundStyle(Color.ivory)
                        }
                    }
                }
                .padding(.vertical, 16)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Color.lineColor).frame(height: 1)
                }
            }

            // 7 CRITERIA ヘッダー
            HStack {
                Text("7 CRITERIA — DETAILED REPORT")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2.5)
                Spacer()
            }
            .padding(.top, 16)
            .padding(.bottom, 4)

            ForEach(Array(result.scores.enumerated()), id: \.element.id) { index, score in
                ScoreCardView(score: score, index: index)
            }
        }
        .aid("diagnosis_score_list")
    }

    // MARK: - Share

    private var sharePrompt: some View {
        let result = diagnosisResult
        return Button {
            Task { await shareResult() }
        } label: {
            HStack(spacing: 14) {
                // シェアカードのミニプレビュー
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

    @ViewBuilder
    private var miniCardPreview: some View {
        let result = appState.analysisResult ?? .mock
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
        let result = appState.analysisResult ?? .mock
        let card = DiagnosisShareCardView(result: result, capturedImage: appState.capturedImage)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            Button {
                appState.navigate(to: .tutorial)
            } label: {
                HStack(spacing: 8) {
                    Text("BEGIN COMPOSITION")
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .kerning(0.5)
                    Text("→")
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                }
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.ivory)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            .aid("diagnosis_begin_button")

            Button {
                appState.navigate(to: .studio)
            } label: {
                Text("Skip to fine tuning")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.inkSecondary.opacity(0.35), lineWidth: 1)
                    )
            }
            .aid("diagnosis_skip_button")
        }
    }
}

// MARK: - ScoreRingView

struct ScoreRingView: View {
    let value: Int
    let size: CGFloat
    @State private var animatedValue: Int = 0

    var body: some View {
        ZStack {
            // 背景サークル
            Circle()
                .stroke(Color.lineColor, lineWidth: 1)

            // 目盛りライン
            tickMarks

            // プログレスアーク
            Circle()
                .trim(from: 0, to: CGFloat(animatedValue) / 100)
                .stroke(
                    Color.ivory,
                    style: StrokeStyle(lineWidth: 2, lineCap: .butt)
                )
                .rotationEffect(.degrees(-90))
                .animation(.interpolatingSpring(duration: 1.4), value: animatedValue)

            // 中央テキスト — 即座に最終値を表示（カウントアップは視覚的に紛らわしいため除去）
            VStack(spacing: 2) {
                Text("\(value)")
                    .font(.system(size: size * 0.30, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Text("OF 100")
                    .font(.system(size: size * 0.07, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.interpolatingSpring(duration: 1.4)) {
                animatedValue = value
            }
        }
    }

    private var tickMarks: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 6
            for i in 0..<20 {
                let angle = Double(i) / 20.0 * 2 * .pi - .pi / 2
                let inner = radius - 4
                let x1 = center.x + cos(angle) * inner
                let y1 = center.y + sin(angle) * inner
                let x2 = center.x + cos(angle) * radius
                let y2 = center.y + sin(angle) * radius
                var path = Path()
                path.move(to: CGPoint(x: x1, y: y1))
                path.addLine(to: CGPoint(x: x2, y: y2))
                context.stroke(path, with: .color(Color.ivory.opacity(0.15)), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - ScoreCardView

struct ScoreCardView: View {
    let score: FaceScore
    let index: Int
    @State private var barProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ヘッダー行
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "n°%02d", index + 1))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1)

                Text(score.name)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Spacer()

                // グレードバッジ
                Text(score.grade)
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(score.gradeColor)
                    .frame(minWidth: 24, alignment: .trailing)

                Text("\(score.score)pt")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }

            // プログレスバー
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.lineColor)
                        .frame(height: 3)

                    Capsule()
                        .fill(score.gradeColor.opacity(0.8))
                        .frame(width: geo.size.width * barProgress, height: 3)
                        .animation(
                            .easeOut(duration: 0.8)
                            .delay(Double(index) * 0.07),
                            value: barProgress
                        )
                }
            }
            .frame(height: 3)

            // アドバイステキスト
            Text(score.advice)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 18)
        .padding(.leading, score.score >= 75 ? 10 : 0)
        .overlay(alignment: .leading) {
            if score.score >= 75 {
                Rectangle()
                    .fill(score.gradeColor)
                    .frame(width: 2)
                    .offset(x: -10)
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
        }
        .onAppear {
            withAnimation(
                .easeOut(duration: 0.8)
                .delay(Double(index) * 0.07)
            ) {
                barProgress = Double(score.score) / 100.0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @MainActor func makeState() -> AppState {
        let state = AppState()
        state.analysisResult = .mock
        let r = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
        state.capturedImage = r.image { ctx in
            UIColor(red: 0.2, green: 0.18, blue: 0.15, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        }
        return state
    }
    return DiagnosisView()
        .environment(makeState())
}
