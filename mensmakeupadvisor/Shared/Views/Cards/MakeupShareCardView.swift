import SwiftUI
import UIKit

// 化粧 (Studio) / 試す (Try) 結果の共有カード。
// 縦長 9:16 (320×568) で診断カードとビジュアルを揃え、主役は renderedImage。
// 下半分にどの化粧単位がどれくらい乗っているかを 4 軸の棒で要約する。
private enum Layout {
    nonisolated static let barWidth: CGFloat = 6
    nonisolated static let barMaxHeight: CGFloat = 56
    nonisolated static let barMinHeight: CGFloat = 2
}

struct MakeupShareCardView: View {
    enum Mode {
        case styled   // Studio: 仕上げた状態
        case tried    // Try: 保存ルックを別の顔で試した状態
    }

    let renderedImage: UIImage?
    let capturedImage: UIImage?
    let composition: MakeupComposition
    let result: AnalysisResult?
    var mode: Mode = .styled
    var date: Date = .now

    private var faceImage: UIImage? { renderedImage ?? capturedImage }

    var body: some View {
        ZStack {
            Color.appBackground

            gridTexture

            Rectangle()
                .stroke(Color.lineColor, lineWidth: Theme.Size.Line.thin)

            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                facePhotoSection
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 0) {
                    statementBlock
                        .padding(.top, 18)

                    HairlineDivider().padding(.top, 16)

                    intensityBars.padding(.top, 14)

                    if let brow = browLabel {
                        HStack(spacing: 6) {
                            Text("BROW")
                                .font(Theme.Typography.Data.tinyRegular)
                                .foregroundStyle(Color.inkTertiary)
                                .kerning(1.5)
                            Text(brow)
                                .font(Theme.Typography.UI.footnoteSemibold)
                                .foregroundStyle(Color.ivory)
                            Spacer()
                        }
                        .padding(.top, 10)
                    }

                    Spacer(minLength: 8)

                    HairlineDivider()
                    bottomBar
                        .padding(.top, 10)
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 28)
            }
        }
        .frame(width: Theme.Size.ShareCard.width, height: Theme.Size.ShareCard.height)
    }

    // MARK: - Background

    private var gridTexture: some View {
        Canvas { context, size in
            let step: CGFloat = 28
            for col in stride(from: CGFloat(0), through: size.width, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: col, y: 0))
                p.addLine(to: CGPoint(x: col, y: size.height))
                context.stroke(p, with: .color(.white.opacity(0.025)), lineWidth: Theme.Size.Line.thin)
            }
            for row in stride(from: CGFloat(0), through: size.height, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: row))
                p.addLine(to: CGPoint(x: size.width, y: row))
                context.stroke(p, with: .color(.white.opacity(0.025)), lineWidth: Theme.Size.Line.thin)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("M · M · A")
                .font(Theme.Typography.Data.smallMedium)
                .foregroundStyle(Color.brandPrimary)
                .kerning(2)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(modeKicker)
                    .font(Theme.Typography.Data.microRegular)
                    .foregroundStyle(Color.inkTertiary)
                    .kerning(1.5)
                Text(modeTitle)
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2)
            }
        }
    }

    private var modeKicker: String {
        switch mode {
        case .styled: "POST-MAKEUP RENDER"
        case .tried:  "TRIED ON · ARCHIVED LOOK"
        }
    }

    private var modeTitle: String {
        switch mode {
        case .styled: "AFTER MAKEUP"
        case .tried:  "TRY-ON RESULT"
        }
    }

    // MARK: - Face Photo

    private var facePhotoSection: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = faceImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Theme.Surface.glassWeak)
                }
            }
            .frame(width: Theme.Size.ShareCard.width, height: Theme.Size.ShareCard.bodyHeight)
            .clipped()
            .overlay(Theme.Surface.shareCardOverlay)
            .overlay(
                LinearGradient(
                    colors: [Color.appBackground, .clear],
                    startPoint: .bottom,
                    endPoint: .init(x: 0.5, y: 0.55)
                )
            )

            HStack(spacing: 6) {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: Theme.Size.Dot.small, height: Theme.Size.Dot.small)
                Text(mode == .styled ? "RENDERED" : "TRY-ON")
                    .font(Theme.Typography.Data.tinyMedium)
                    .foregroundStyle(Color.ivory)
                    .kerning(1.5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.appBackground.opacity(0.6)))
            .padding(.leading, 18)
            .padding(.bottom, 18)
        }
        .frame(width: Theme.Size.ShareCard.width, height: Theme.Size.ShareCard.bodyHeight)
    }

    // MARK: - Statement

    // 主役の一言。診断カードのスコアブロックに相当する位置で、
    // 「どんな顔タイプ向けに、どんな化粧にしたか」を 1 行で語る。
    private var statementBlock: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if let result {
                    Text(result.faceShape.label.uppercased())
                        .font(Theme.Typography.Data.miniRegular)
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(2)
                } else {
                    Text("MAKEUP COMPOSITION")
                        .font(Theme.Typography.Data.miniRegular)
                        .foregroundStyle(Color.inkSecondary)
                        .kerning(2)
                }
                Text(statementLine)
                    .font(Theme.Typography.Display.titleLight)
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
    }

    private var statementLine: String {
        switch mode {
        case .styled: "this is my finish."
        case .tried:  "trying this on me."
        }
    }

    // MARK: - Intensity bars

    // base / highlight / shadow / eye の 4 軸を縦バーで要約。
    // 詳細スコアより「何にどれくらい寄せたか」のシルエットを残すのが目的。
    private var intensityBars: some View {
        HStack(alignment: .bottom, spacing: 14) {
            ForEach(axes, id: \.label) { axis in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        Capsule()
                            .fill(Color.ivory.opacity(0.12))
                            .frame(width: Layout.barWidth, height: Layout.barMaxHeight)
                        Capsule()
                            .fill(Color.ivory.opacity(0.85))
                            .frame(width: Layout.barWidth, height: max(Layout.barMinHeight, CGFloat(axis.value) * Layout.barMaxHeight))
                    }
                    Text(axis.label)
                        .font(Theme.Typography.UI.caption2Medium)
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var axes: [(label: String, value: Float)] {
        let eye = max(
            composition.intensity(of: .eyeshadow),
            composition.intensity(of: .tearbag),
            composition.intensity(of: .eyeliner)
        )
        return [
            ("肌", composition.intensity(of: .base)),
            ("光", composition.intensity(of: .highlight)),
            ("影", composition.intensity(of: .shadow)),
            ("目", eye),
        ]
    }

    private var browLabel: String? {
        switch composition.browType {
        case .natural?:  "ナチュラル"
        case .straight?: "ストレート"
        case .arch?:     "アーチ"
        case .parallel?: "平行"
        case .corner?:   "角度あり"
        case nil:        nil
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("MensMakeupAdvisor")
                    .font(Theme.Typography.Data.smallSemibold)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .kerning(1)
                Text(date, format: .dateTime.year().month().day())
                    .font(Theme.Typography.Data.miniRegular)
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(0.5)
            }
            Spacer()
            if let result {
                Text(result.grade)
                    .font(Theme.Typography.Data.baseBlack)
                    .foregroundStyle(result.gradeColor)
            }
        }
    }
}

#Preview("Studio") {
    MakeupShareCardView(
        renderedImage: nil,
        capturedImage: nil,
        composition: MakeupComposition(),
        result: .mock,
        mode: .styled
    )
}

#Preview("Try") {
    MakeupShareCardView(
        renderedImage: nil,
        capturedImage: nil,
        composition: MakeupComposition(),
        result: .mock,
        mode: .tried
    )
}
