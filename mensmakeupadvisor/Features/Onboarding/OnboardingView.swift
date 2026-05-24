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
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var chapterIndexButton: some View {
        Button {
            Haptics.soft()
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
    // 最終ページの CTA ラベル/遷移先を「ホームに戻る」「撮影をはじめる」で出し分けるためだけに使う。
    private var isRereadFromHome: Bool {
        appState.analysisResult != nil
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

    // MARK: - Navigation: 最終ページは CTA、それ以外はスワイプヒント

    private var navigationBar: some View {
        Group {
            if currentPage == pages.count - 1 {
                GlassPrimaryButton(
                    title: isRereadFromHome ? "ホームに戻る" : "撮影をはじめる",
                    icon: isRereadFromHome ? "house.fill" : "camera.fill",
                    accessibilityID: "onboarding_continue_button"
                ) {
                    Haptics.medium()
                    if isRereadFromHome {
                        appState.navigation.navigate(to: .home)
                    } else {
                        appState.navigation.openCapture(from: .onboarding)
                    }
                }
            } else {
                // 中間ページは「スワイプで進む」を明示。タップでも次ページに送る。
                // 旧 UI ではスワイプ可能性が伝わらず、止まるユーザーがいた。
                HStack {
                    Spacer()
                    Button {
                        Haptics.selection()
                        withAnimation(Theme.Motion.smooth) {
                            currentPage = min(currentPage + 1, pages.count - 1)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("SWIPE")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .kerning(2.5)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .opacity(0.5)
                        }
                        .foregroundStyle(Theme.Text.primaryFaded)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .glassEffect(.clear, in: .capsule)
                    }
                    .accessibilityLabel("次のページへ")
                    .aid("onboarding_next_hint")
                    Spacer()
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
