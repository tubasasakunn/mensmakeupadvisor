import SwiftUI

// 保存ルックの total score 推移を描く折れ線スパークライン。
//
// Swift Charts を使わず Path で手描きするのは、本アプリが顔メッシュや
// スコアリングを全て自前描画する editorial な作画方針を取っており、
// 既定チャートの見た目が浮くため。少数データ (1〜数十点) 前提で軽量に描く。
private enum Layout {
    nonisolated static let chartHeight: CGFloat = 150
    nonisolated static let gridLine: CGFloat = 0.5
}

struct ScoreTrendChart: View {
    let points: [ProgressMetrics.Point]

    var body: some View {
        GeometryReader { geo in
            let pts = positions(in: geo.size)

            ZStack {
                gridLines(in: geo.size)

                if pts.count >= 2 {
                    areaFill(pts, height: geo.size.height)
                    linePath(pts)
                }

                dots(pts)
            }
        }
        .frame(height: Layout.chartHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .aid("progress_trend_chart")
    }

    // MARK: - Geometry

    // y 軸ドメイン: データに 8pt の余白を足し 0...100 にクランプ。
    // わずかなスコア差でも視認できるよう、ドメインを詰める。
    private var domain: ClosedRange<Double> {
        let scores = points.map { Double($0.score) }
        let lo = max(0, (scores.min() ?? 0) - 8)
        let hi = min(100, (scores.max() ?? 100) + 8)
        return lo < hi ? lo...hi : 0...100
    }

    private func positions(in size: CGSize) -> [CGPoint] {
        guard !points.isEmpty else { return [] }
        let lo = domain.lowerBound
        let span = max(domain.upperBound - lo, 0.001)
        let n = points.count
        return points.enumerated().map { idx, p in
            let x = n == 1 ? size.width / 2 : size.width * CGFloat(idx) / CGFloat(n - 1)
            let yNorm = (Double(p.score) - lo) / span
            let y = size.height * (1 - CGFloat(yNorm))
            return CGPoint(x: x, y: y)
        }
    }

    // MARK: - Layers

    private func gridLines(in size: CGSize) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { _ in
                Rectangle()
                    .fill(Theme.Mesh.tickMark)
                    .frame(height: Layout.gridLine)
                Spacer()
            }
            Rectangle()
                .fill(Theme.Mesh.tickMark)
                .frame(height: Layout.gridLine)
        }
    }

    private func areaFill(_ pts: [CGPoint], height: CGFloat) -> some View {
        Path { path in
            guard let first = pts.first else { return }
            path.move(to: CGPoint(x: first.x, y: height))
            path.addLine(to: first)
            for p in pts.dropFirst() { path.addLine(to: p) }
            if let last = pts.last {
                path.addLine(to: CGPoint(x: last.x, y: height))
            }
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [Theme.Accent.primarySubtle, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func linePath(_ pts: [CGPoint]) -> some View {
        Path { path in
            guard let first = pts.first else { return }
            path.move(to: first)
            for p in pts.dropFirst() { path.addLine(to: p) }
        }
        .stroke(
            Theme.Line.progressFill,
            style: StrokeStyle(lineWidth: Theme.Size.Line.strong, lineCap: .round, lineJoin: .round)
        )
    }

    private func dots(_ pts: [CGPoint]) -> some View {
        ForEach(Array(pts.enumerated()), id: \.offset) { idx, p in
            let isLast = idx == pts.count - 1
            Circle()
                .fill(isLast ? Theme.Accent.primary : Color.ivory)
                .frame(width: isLast ? 8 : 4, height: isLast ? 8 : 4)
                .overlay(
                    Circle().stroke(Color.ivory.opacity(isLast ? 0.9 : 0), lineWidth: Theme.Size.Line.regular)
                )
                .position(p)
        }
    }

    private var accessibilitySummary: String {
        guard let first = points.first, let last = points.last else {
            return "推移データなし"
        }
        return "スコア推移グラフ。\(first.score)pt から \(last.score)pt まで \(points.count) 件の記録。"
    }
}

#Preview {
    ZStack {
        LuxeBackground()
        ScoreTrendChart(points: [
            .init(id: "1", date: .now.addingTimeInterval(-86400 * 30), score: 58),
            .init(id: "2", date: .now.addingTimeInterval(-86400 * 20), score: 64),
            .init(id: "3", date: .now.addingTimeInterval(-86400 * 12), score: 61),
            .init(id: "4", date: .now.addingTimeInterval(-86400 * 5), score: 72),
            .init(id: "5", date: .now, score: 78),
        ])
        .padding(Theme.Spacing.xxl)
    }
}
