import SwiftUI

struct SplashView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            // 四隅の十字マーク
            cornerMarks

            VStack(spacing: 0) {
                // 上部メタ情報
                topMeta
                    .padding(.top, 56)

                Spacer()

                // 中央タイポグラフィブロック
                centerBlock

                Spacer()

                // 下部
                bottomBlock
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 28)
        }
        .task {
            try? await Task.sleep(for: .seconds(2.2))
            appState.navigate(to: .onboarding)
        }
        .accessibilityIdentifier("splash_view")
    }

    // MARK: - Subviews

    private var topMeta: some View {
        HStack {
            Text("Vol. 01 — Issue No. 001")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .textCase(.lowercase)
            Spacer()
            Text("A.W. 25/26")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .textCase(.lowercase)
        }
    }

    private var centerBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            // "A QUIET STUDY IN"
            Text("A QUIET STUDY IN")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)
                .padding(.bottom, 16)

            // "The"
            Text("The")
                .font(.system(size: 72, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .padding(.bottom, -8)

            // "Better"
            Text("Better")
                .font(.system(size: 80, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .padding(.bottom, -8)

            // "Self." — バーガンディ赤
            Text("Self.")
                .font(.system(size: 80, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            // 区切り線
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.top, 24)
                .padding(.bottom, 16)

            // 日本語キャッチコピー
            Text("紳士の身嗜み、再考。")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBlock: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text("EST. MMXXV")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2.0)
                Text("Hommes · Atelier")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }
            Spacer()
        }
    }

    private var cornerMarks: some View {
        GeometryReader { geo in
            let size = geo.size
            let offset: CGFloat = 20
            let markOpacity = 0.25

            ZStack {
                // 左上
                CrossMark()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.ivory.opacity(markOpacity))
                    .position(x: offset, y: offset)

                // 右上
                CrossMark()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.ivory.opacity(markOpacity))
                    .position(x: size.width - offset, y: offset)

                // 左下
                CrossMark()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.ivory.opacity(markOpacity))
                    .position(x: offset, y: size.height - offset)

                // 右下
                CrossMark()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.ivory.opacity(markOpacity))
                    .position(x: size.width - offset, y: size.height - offset)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - CrossMark Shape

private struct CrossMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cx = rect.midX
        let cy = rect.midY
        let half = min(rect.width, rect.height) / 2
        // 横線
        path.move(to: CGPoint(x: cx - half, y: cy))
        path.addLine(to: CGPoint(x: cx + half, y: cy))
        // 縦線
        path.move(to: CGPoint(x: cx, y: cy - half))
        path.addLine(to: CGPoint(x: cx, y: cy + half))
        return path
    }
}

// MARK: - Preview

#Preview {
    SplashView()
        .environment(AppState())
}
