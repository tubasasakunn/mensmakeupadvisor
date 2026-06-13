import SwiftUI
import UIKit

struct ScoreCardView: View {
    let score: FaceScore
    let index: Int
    // expand 時に評価対象を線で示すための入力
    var capturedImage: UIImage? = nil
    var landmarks: [CGPoint]? = nil

    @State private var barProgress: Double = 0
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            headerRow
            progressBar
            adviceText

            if isExpanded {
                // 高さ変化と中身の出現を 1 つの transition にまとめる。
                // `.opacity` 単独だと閉じる際にビュー枠は残ったまま fade するため
                // 顔図だけ取り残されて見える。`.move(edge: .top) + .opacity` で
                // 上に畳まれながら消える挙動にする。
                expandedAnnotation
                    .padding(.top, Theme.Spacing.xs)
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        .padding(.vertical, Theme.Spacing.lg)
        .padding(.leading, score.score >= 75 ? Theme.Spacing.md : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(Theme.Motion.smooth) {
                isExpanded.toggle()
            }
        }
        .overlay(alignment: .leading) {
            if score.score >= 75 {
                Rectangle()
                    .fill(score.gradeColor)
                    .frame(width: 2)
                    .offset(x: -10)
            }
        }
        .overlay(alignment: .bottom) {
            HairlineDivider()
        }
        .aid("diagnosis_score_card_\(score.name)")
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(Double(index) * 0.07)) {
                barProgress = Double(score.score) / 100.0
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(index + 1).")
                .font(Theme.Typography.UI.calloutRegular)
                .foregroundStyle(Color.inkTertiary)

            Text(score.name)
                .font(Theme.Typography.UI.bodyLargeSemibold)
                .foregroundStyle(Color.ivory)

            Spacer()

            Text(score.grade)
                .font(Theme.Typography.UI.title3Heavy)
                .foregroundStyle(score.gradeColor)
                .frame(minWidth: 24, alignment: .trailing)

            Text("\(score.score) 点")
                .font(Theme.Typography.UI.subheadlineMedium)
                .foregroundStyle(Color.inkSecondary)

            Image(systemName: "chevron.down")
                .font(Theme.Typography.UI.subheadlineMedium)
                .foregroundStyle(Color.inkSecondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .animation(.easeInOut(duration: 0.25), value: isExpanded)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.lineColor)
                    .frame(height: 3)

                Capsule()
                    .fill(score.gradeColor.opacity(0.8))
                    .frame(width: geo.size.width * barProgress, height: 3)
                    .animation(
                        .easeOut(duration: 0.8).delay(Double(index) * 0.07),
                        value: barProgress
                    )
            }
        }
        .frame(height: 3)
    }

    private var adviceText: some View {
        Text(score.advice)
            .font(Theme.Typography.UI.subheadlineRegular)
            .foregroundStyle(Color.inkSecondary)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var expandedAnnotation: some View {
        if capturedImage != nil, landmarks?.isEmpty == false {
            VStack(alignment: .leading, spacing: 6) {
                ScoreAnnotationView(
                    scoreName: score.name,
                    capturedImage: capturedImage,
                    landmarks: landmarks
                )
                Text(annotationCaption)
                    .font(Theme.Typography.UI.footnoteRegular)
                    .foregroundStyle(Color.inkTertiary)
            }
        } else {
            Text("画像が読み込まれていないため、評価線を表示できません。")
                .font(Theme.Typography.UI.footnote)
                .foregroundStyle(Color.inkTertiary)
        }
    }

    private var annotationCaption: String {
        switch score.name {
        case "骨格バランス": "図 · 顔幅・顔高・頬骨ライン"
        case "三分割比率":   "図 · 額／中顔面／下顔面"
        case "五分割比率":   "図 · こめかみ〜目尻〜目頭"
        case "目の比率":     "図 · 目の縦×横"
        case "鼻のバランス": "図 · 鼻幅と目間の対比"
        case "口の比率":     "図 · 口幅と上下唇の厚み"
        case "左右対称性":   "図 · 中央線とペア点"
        default: ""
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ScoreCardView(score: AnalysisResult.mock.scores[0], index: 0)
        ScoreCardView(score: AnalysisResult.mock.scores[1], index: 1)
    }
    .padding(.horizontal, 24)
    .background(Color.appBackground)
}
