import SwiftData
import SwiftUI

// アプリのホーム画面。TabView で 3 タブ:
//   ① REPORT  — 直近の顔評価サマリ + 再評価
//   ② CREATE  — 化粧作成 CTA (capture フローを開始)
//   ③ ARCHIVE — 保存ルックのグリッド (mesh ベース)
struct HomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        TabView(selection: $appState.homeTab) {
            HomeReportTab()
                .tabItem {
                    Label("診断", systemImage: "doc.text.magnifyingglass")
                }
                .tag(HomeTab.report)
                .aid("home_tab_report")

            HomeCreateTab()
                .tabItem {
                    Label("撮影", systemImage: "camera.fill")
                }
                .tag(HomeTab.create)
                .aid("home_tab_create")

            HomeArchiveTab()
                .tabItem {
                    Label("保存", systemImage: "square.grid.2x2")
                }
                .tag(HomeTab.archive)
                .aid("home_tab_archive")

            HomeSettingsTab()
                .tabItem {
                    Label("アトリエ", systemImage: "circle.dotted")
                }
                .tag(HomeTab.settings)
                .aid("home_tab_settings")
        }
        .tint(Color.ivory)
        // iOS 26: Tab bar も Liquid Glass の上に乗るようにする
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
        .accessibilityElement(children: .contain)
        .aid("home_view")
        // Home に戻ってきた時点で Create フラグはクリアする。
        // HomeCreateTab で立てた後、別タブから Diagnosis に行くなどの
        // 経路で残留して Tutorial がスキップされる事故を防ぐ。
        // 併せて「ホーム到達済み」フラグを立て、次回起動時に Onboarding を
        // 飛ばして直接 Home に来られるようにする。
        .task {
            appState.skipTutorialOnNextFlow = false
            AppEnvironment.didReachHomeOnce = true
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
