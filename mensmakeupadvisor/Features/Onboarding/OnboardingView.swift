import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0
    @State private var showChapterSheet = false

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.5)

            VStack(spacing: 0) {
                headerBar
                progressBar
                folioBar

                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        OnboardPageContentView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                navigationBar
            }
        }
        .sheet(isPresented: $showChapterSheet) {
            OnboardingChapterSheet(currentPage: $currentPage)
        }
        // 親に付けた identifier を子に継承させない。SwiftUI のデフォルト挙動だと
        // 子の Button の identifier が "onboarding_view" で上書きされる。
        .accessibilityElement(children: .contain)
        .aid("onboarding_view")
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 10) {
            chapterIndexButton

            Text(pages[currentPage].tag)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1.5)
                .animation(.none, value: currentPage)
                .aid("onboarding_page_tag")

            Spacer()
            skipButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var chapterIndexButton: some View {
        Button {
            showChapterSheet = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 11, weight: .medium))
                Text("目次")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 7)
            .glassEffect(.clear, in: .capsule)
        }
        .accessibilityLabel("目次を開く")
        .aid("onboarding_chapter_button")
    }

    // Home から再読しているか (analysisResult があれば一度はアプリを使った人)。
    // 初回フローでは「読み飛ばす → 撮影画面」、再読では「ホームに戻る」にする。
    private var isRereadFromHome: Bool {
        appState.analysisResult != nil
    }

    private var skipButton: some View {
        Button {
            appState.navigate(to: isRereadFromHome ? .home : .capture)
        } label: {
            Text(isRereadFromHome ? "ホームに戻る" : "読み飛ばす")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.Text.primarySoft)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 7)
                .glassEffect(.clear, in: .capsule)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRereadFromHome ? "ホームに戻る" : "読み飛ばして撮影画面へ")
        .aid("onboarding_skip_button")
    }

    // MARK: - Progress hairline

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HairlineDivider(height: 1.5)
                HairlineDivider(color: Theme.Text.primaryFaded, height: 1.5)
                    .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(pages.count))
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
        .frame(height: 1.5)
        .padding(.horizontal, 28)
        .padding(.bottom, 6)
        .aid("onboarding_progress_bar")
    }

    // MARK: - Folio

    private var folioBar: some View {
        HStack {
            Spacer()
            Text("\(currentPage + 1) / \(pages.count) ページ")
                .font(.system(size: 11))
                .foregroundStyle(Theme.Text.secondaryFaded)
                .accessibilityLabel("\(currentPage + 1) ページ目、全 \(pages.count) ページ中")
                .aid("onboarding_folio_label")
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 4)
    }

    // MARK: - Navigation: BEGIN on last page only

    private var navigationBar: some View {
        HStack {
            if currentPage == pages.count - 1 {
                GlassPrimaryButton(
                    title: isRereadFromHome ? "ホームに戻る" : "撮影をはじめる",
                    icon: isRereadFromHome ? "house.fill" : "camera.fill",
                    accessibilityID: "onboarding_continue_button"
                ) {
                    appState.navigate(to: isRereadFromHome ? .home : .capture)
                }
            }
        }
        .frame(height: 60)
        .padding(.horizontal, Theme.Spacing.xxl)
        .padding(.bottom, Theme.Spacing.xxxl)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
