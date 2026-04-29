# SwiftUI アーキテクチャ・状態管理パターン

## 状態管理の全体方針

| 用途 | 使うもの | 禁止 |
|---|---|---|
| ViewModel（ローカル） | `@State private var vm = XxxViewModel()` | `@StateObject` |
| ViewModel（外部注入） | `let vm: XxxViewModel`（引数） | `@ObservedObject` |
| グローバル状態 | `@Environment` カスタムキー | グローバルシングルトン |
| SwiftData | `@Query`, `@Environment(\.modelContext)` | `@FetchRequest` |
| UI一時状態 | `@State` | — |
| バインディング | `@Binding` | — |

## View の設計原則

```swift
// 1 View = 1 責任。200行を超えたら分割する
// computed property で body を分割
struct AdviceView: View {
    @State private var viewModel = AdviceViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                imageSection
                recommendationsSection
            }
        }
        .task { await viewModel.load() }
    }

    // ❌ body の中に 100行のコードを書かない
    // ✅ private computed property に切り出す
    private var headerSection: some View {
        VStack(alignment: .leading) {
            Text("今日のアドバイス")
                .font(.title2.bold())
            Text("あなたの肌に合わせたメイクを提案します")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var imageSection: some View {
        ImagePickerCard(
            selectedImage: $viewModel.selectedImage,
            onCapture: { image in
                Task { await viewModel.analyze(image: image) }
            }
        )
        .accessibilityIdentifier("advice_image_picker")
    }

    @ViewBuilder
    private var recommendationsSection: some View {
        if viewModel.isLoading {
            ProgressView("分析中...")
                .accessibilityIdentifier("advice_loading_indicator")
        } else if viewModel.recommendations.isEmpty {
            EmptyRecommendationsView()
        } else {
            RecommendationList(items: viewModel.recommendations)
        }
    }
}
```

## ViewModel パターン

```swift
// 必ず final class + @Observable
@Observable
final class AdviceViewModel {
    // MARK: - Output（View が読む）
    var selectedImage: UIImage?
    var recommendations: [Recommendation] = []
    var isLoading: Bool = false
    var analysisState: AnalysisState = .idle

    // MARK: - Dependencies
    private let analysisService: AnalysisServiceProtocol
    private let historyService: HistoryServiceProtocol

    init(
        analysisService: AnalysisServiceProtocol = AnalysisService(),
        historyService: HistoryServiceProtocol = HistoryService()
    ) {
        self.analysisService = analysisService
        self.historyService = historyService
    }

    // MARK: - Intent（View から呼ぶ）
    func load() async {
        // 初期データ取得
    }

    func analyze(image: UIImage) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await analysisService.analyze(image: image)
            recommendations = result.recommendations
            analysisState = .success
            await historyService.save(result)
        } catch {
            analysisState = .failure(error)
        }
    }
}

enum AnalysisState: Equatable {
    case idle, loading, success
    case failure(Error)

    static func == (lhs: AnalysisState, rhs: AnalysisState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success): true
        case (.failure, .failure): true
        default: false
        }
    }
}
```

## 依存性注入（Environment パターン）

```swift
// Services/ServiceKeys.swift
// ── プロトコル定義
protocol AnalysisServiceProtocol: Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult
}

// ── EnvironmentKey 定義
private struct AnalysisServiceKey: EnvironmentKey {
    static let defaultValue: any AnalysisServiceProtocol = AnalysisService()
}

extension EnvironmentValues {
    var analysisService: any AnalysisServiceProtocol {
        get { self[AnalysisServiceKey.self] }
        set { self[AnalysisServiceKey.self] = newValue }
    }
}

// ── View で使う
struct AdviceView: View {
    @Environment(\.analysisService) private var analysisService
}

// ── Preview / テストで差し替え
#Preview {
    AdviceView()
        .environment(\.analysisService, MockAnalysisService())
}
```

## ナビゲーション（NavigationStack 必須）

```swift
// ❌ NavigationView 禁止
// ✅ NavigationStack + 型安全ルーティング

// Navigation/AppRouter.swift
@Observable
final class AppRouter {
    var path: NavigationPath = NavigationPath()

    enum Destination: Hashable {
        case adviceDetail(Recommendation)
        case productDetail(MakeupProduct)
        case historyDetail(AdviceHistory)
        case settings
    }

    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}

// RootView.swift
struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRouter.Destination.self) { destination in
                    switch destination {
                    case .adviceDetail(let rec):   AdviceDetailView(recommendation: rec)
                    case .productDetail(let prod): ProductDetailView(product: prod)
                    case .historyDetail(let hist): HistoryDetailView(history: hist)
                    case .settings:                SettingsView()
                    }
                }
        }
        .environment(router)
    }
}
```

## TabView（iOS 18+ スタイル）

```swift
// TabView は App エントリか RootView で 1箇所のみ定義
TabView {
    Tab("ホーム", systemImage: "house.fill") {
        HomeView()
            .accessibilityIdentifier("tab_home")
    }
    Tab("アドバイス", systemImage: "wand.and.stars") {
        AdviceView()
            .accessibilityIdentifier("tab_advice")
    }
    Tab("履歴", systemImage: "clock.arrow.circlepath") {
        HistoryView()
            .accessibilityIdentifier("tab_history")
    }
    Tab("プロフィール", systemImage: "person.crop.circle") {
        ProfileView()
            .accessibilityIdentifier("tab_profile")
    }
}
.tabViewStyle(.sidebarAdaptable)  // iPad 対応
```

## SwiftData 統合

```swift
// @Model は必ず final class
@Model
final class AdviceHistory {
    var id: UUID
    var createdAt: Date
    var imageData: Data?
    var recommendationsJSON: String  // Codable を JSON 変換して保存

    // 1対多リレーション
    @Relationship(deleteRule: .cascade) var items: [HistoryItem] = []

    init(id: UUID = UUID(), createdAt: Date = .now) {
        self.id = id
        self.createdAt = createdAt
    }
}

// View での使用
struct HistoryView: View {
    @Query(sort: \AdviceHistory.createdAt, order: .reverse)
    private var histories: [AdviceHistory]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List(histories) { history in
            HistoryRowView(history: history)
        }
    }
}
```

## Preview

```swift
// 全 Preview はインメモリ ModelContainer を使う
#Preview {
    AdviceView()
        .modelContainer(for: [AdviceHistory.self, HistoryItem.self], inMemory: true)
        .environment(\.analysisService, MockAnalysisService())
}

// サイズバリアント
#Preview("iPhone SE", traits: .sizeThatFitsLayout) {
    ProductCard(product: .mock)
}

#Preview("Dark Mode", traits: .init()) {
    HomeView()
        .preferredColorScheme(.dark)
}
```

## 禁止パターン

```swift
// ❌ @StateObject / @ObservedObject
@StateObject private var vm = ViewModel()

// ❌ .onAppear でデータ取得（.task を使う）
.onAppear { viewModel.load() }  // 非同期なら .task

// ❌ 巨大な body
var body: some View {
    // 300行のコード
}

// ❌ NavigationView
NavigationView { ... }

// ❌ NavigationLink(destination:) の古い形式
NavigationLink(destination: DetailView()) { ... }
// ✅ NavigationLink(value:) を使う
NavigationLink(value: AppRouter.Destination.adviceDetail(rec)) { ... }
```
