import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPage = 0

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                progressBar
                folioBar
                pageContent
                navigationBar
            }
        }
        .accessibilityIdentifier("onboarding_view")
    }

    // MARK: - Header: tag + skip

    private var headerBar: some View {
        HStack {
            Text(pages[currentPage].tag)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)
                .animation(.none, value: currentPage)
                .accessibilityIdentifier("onboarding_page_tag")

            Spacer()

            Button("Skip →") {
                appState.navigate(to: .capture)
            }
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .accessibilityIdentifier("onboarding_skip_button")
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Progress hairline

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1.5)
                Rectangle()
                    .fill(Color.ivory.opacity(0.7))
                    .frame(width: geo.size.width * CGFloat(currentPage + 1) / CGFloat(pages.count), height: 1.5)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
        .frame(height: 1.5)
        .padding(.horizontal, 28)
        .padding(.bottom, 6)
        .accessibilityIdentifier("onboarding_progress_bar")
    }

    // MARK: - Folio "p. 001 of 033"

    private var folioBar: some View {
        HStack {
            Spacer()
            Text("p. \(String(format: "%03d", currentPage + 1)) of \(String(format: "%03d", pages.count))")
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.inkSecondary.opacity(0.6))
                .kerning(1)
                .accessibilityIdentifier("onboarding_folio_label")
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 4)
    }

    // MARK: - Page content with transitions

    private var pageContent: some View {
        OnboardPageContentView(page: pages[currentPage])
            .id(currentPage)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal: .opacity.combined(with: .move(edge: .leading))
            ))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("onboarding_page_content")
            .highPriorityGesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        let horizontal = abs(value.translation.width)
                        let vertical = abs(value.translation.height)
                        guard horizontal > vertical else { return }
                        if value.translation.width < -60 {
                            // 左スワイプ: 次ページ
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if currentPage < pages.count - 1 {
                                    currentPage += 1
                                }
                            }
                        } else if value.translation.width > 60 {
                            // 右スワイプ: 前ページ
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if currentPage > 0 {
                                    currentPage -= 1
                                }
                            }
                        }
                    }
            )
    }

    // MARK: - Navigation: Back + Continue

    private var navigationBar: some View {
        HStack {
            if currentPage > 0 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage -= 1
                    }
                } label: {
                    Text("← Back")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .accessibilityIdentifier("onboarding_back_button")
            } else {
                EmptyView()
            }

            Spacer()

            // 最終ページ以外: 丸矢印ボタン / 最終ページ: BEGIN capsule
            if currentPage == pages.count - 1 {
                Button {
                    nextPage()
                } label: {
                    HStack(spacing: 6) {
                        Text("BEGIN")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .kerning(1.5)
                            .foregroundStyle(Color.ivory)

                        Text("→")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ivory)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                }
                .glassEffect(.regular, in: .capsule)
                .accessibilityIdentifier("onboarding_continue_button")
            } else {
                Button {
                    nextPage()
                } label: {
                    Text("→")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color.ivory)
                        .padding(16)
                }
                .glassEffect(.regular, in: .circle)
                .accessibilityIdentifier("onboarding_continue_button")
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
        .padding(.top, 8)
    }

    // MARK: - Navigation logic

    private func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        } else {
            appState.navigate(to: .capture)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environment(AppState())
}
