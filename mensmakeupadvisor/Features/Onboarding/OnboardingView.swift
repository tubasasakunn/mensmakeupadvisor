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
        // 親に付けた identifier を子に継承させない。SwiftUI のデフォルト挙動だと
        // 子の Button の identifier が "onboarding_view" で上書きされる。
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("onboarding_view")
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text(pages[currentPage].tag)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2.5)
                .animation(.none, value: currentPage)
                .accessibilityIdentifier("onboarding_page_tag")
            Spacer()
            skipButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var skipButton: some View {
        Button {
            appState.navigate(to: .capture)
        } label: {
            Text("読み飛ばす")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.inkSecondary.opacity(0.4), lineWidth: 1)
                )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("読み飛ばして撮影画面へ")
        .accessibilityIdentifier("onboarding_skip_button")
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

    // MARK: - Folio

    private var folioBar: some View {
        HStack {
            Spacer()
            Text("\(currentPage + 1) / \(pages.count) ページ")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSecondary.opacity(0.7))
                .accessibilityLabel("\(currentPage + 1) ページ目、全 \(pages.count) ページ中")
                .accessibilityIdentifier("onboarding_folio_label")
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 4)
    }

    // MARK: - Navigation: BEGIN on last page only

    private var navigationBar: some View {
        HStack {
            Spacer()
            if currentPage == pages.count - 1 {
                Button {
                    appState.navigate(to: .capture)
                } label: {
                    HStack(spacing: 8) {
                        Text("撮影をはじめる")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.ivory)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.ivory)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                }
                .glassEffect(.regular, in: .capsule)
                .accessibilityLabel("撮影をはじめる")
                .accessibilityIdentifier("onboarding_continue_button")
            }
        }
        .frame(height: 60)
        .padding(.horizontal, 28)
        .padding(.bottom, 32)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
