import SwiftUI

// Studio で「次へ」を押した直後に挟む穏やかな送り出し画面。
// 直接ホームに飛ばさず、ひと呼吸置いて「今日のあなたが整いました」を伝える。
// CTA を 1 つだけ置き、タップでホームへ。
struct CompletionView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.55)

            VStack(spacing: 0) {
                topMeta
                    .padding(.top, Theme.Spacing.xxl)
                    .padding(.horizontal, Theme.Spacing.xxl)

                Spacer(minLength: 0)

                centerBlock
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.6), value: appeared)

                Spacer(minLength: 0)

                ctaBlock
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.bottom, Theme.Spacing.xxxl)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(0.25), value: appeared)
            }
        }
        .accessibilityElement(children: .contain)
        .aid("completion_view")
        .task {
            // 入った瞬間に Studio の触覚を引き継いで「整いました」の合図を出す。
            Haptics.success()
            appeared = true
        }
    }

    // MARK: - Subviews

    private var topMeta: some View {
        HStack {
            Text("CHAPTER 08 · BEGIN")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Theme.Text.secondaryFaded)
                .kerning(2.8)
            Spacer()
            Text("FIN.")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.Text.primaryFaded)
                .kerning(2.5)
        }
    }

    private var centerBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("ready.")
                .font(.system(size: 42, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Theme.Text.primaryFaded)

            // 仕上げが終わったタイミングなので「これから始める」ではなく
            // 一日に送り出す表現に。"はじめましょう" は最初の頃を匂わせて違和感が出る。
            Text("さぁ、\n出かけましょう。")
                .font(.system(size: 44, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)

            HairlineDivider()
                .padding(.top, Theme.Spacing.md)

            Text("今日のあなたのスタイルが整いました。\n鏡を一度だけ。あとは、外へ。")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(6)
                .padding(.top, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ctaBlock: some View {
        VStack(spacing: Theme.Spacing.md) {
            GlassPrimaryButton(
                title: "ホームへ",
                icon: "house.fill",
                accessibilityID: "completion_continue_button"
            ) {
                Haptics.medium()
                appState.navigate(to: .home)
            }
        }
    }
}

#Preview {
    CompletionView()
        .environment(AppState())
}
