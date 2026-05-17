import SwiftData
import SwiftUI

// アプリのホーム画面。TabView で 3 タブ:
//   ① REPORT  — 直近の顔評価サマリ + 再評価
//   ② CREATE  — 化粧作成 CTA (capture フローを開始)
//   ③ ARCHIVE — 保存ルックのグリッド (mesh ベース)
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var selection: Tab = .create

    enum Tab: Hashable {
        case report, create, archive
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeReportTab()
                .tabItem {
                    Label("REPORT", systemImage: "doc.text.magnifyingglass")
                }
                .tag(Tab.report)
                .aid("home_tab_report")

            HomeCreateTab()
                .tabItem {
                    Label("CREATE", systemImage: "sparkles")
                }
                .tag(Tab.create)
                .aid("home_tab_create")

            HomeArchiveTab()
                .tabItem {
                    Label("ARCHIVE", systemImage: "square.grid.2x2")
                }
                .tag(Tab.archive)
                .aid("home_tab_archive")
        }
        .tint(Color.ivory)
        .background(Color.appBackground)
        .accessibilityElement(children: .contain)
        .aid("home_view")
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
