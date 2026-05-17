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
        VStack(alignment: .leading, spacing: 12) {
            headerRow
            progressBar
            adviceText

            if isExpanded {
                // 親 VStack の高さ変化で自然に下方向に展開させ、内容は
                // fade in だけにする。.move(edge: .top) を入れていた
                // ときは「上から滑り落ちて来る」見た目で違和感があった。
                expandedAnnotation
                    .padding(.top, 6)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 18)
        .padding(.leading, score.score >= 75 ? 10 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.28), value: isExpanded)
        .contentShape(Rectangle())
        .onTapGesture {
            isExpanded.toggle()
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
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
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
            Text(String(format: "n°%02d", index + 1))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkTertiary)
                .kerning(1)

            Text(score.name)
                .font(.system(size: 14, weight: .medium, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)

            Spacer()

            Text(score.grade)
                .font(.system(size: 18, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(score.gradeColor)
                .frame(minWidth: 24, alignment: .trailing)

            Text("\(score.score)pt")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)

            // expand chevron
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .medium))
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
            .font(.system(size: 12, weight: .regular))
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
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.2)
            }
        } else {
            Text("画像が読み込まれていないため、評価線を表示できません。")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkTertiary)
        }
    }

    private var annotationCaption: String {
        switch score.name {
        case "骨格バランス": "FIG · 顔幅・顔高・頬骨ライン"
        case "三分割比率":   "FIG · 額／中顔面／下顔面"
        case "五分割比率":   "FIG · こめかみ〜目尻〜目頭"
        case "目の比率":     "FIG · 目の縦×横"
        case "鼻のバランス": "FIG · 鼻幅と目間の対比"
        case "口の比率":     "FIG · 口幅と上下唇の厚み"
        case "左右対称性":   "FIG · 中央線とペア点"
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
