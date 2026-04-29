# Swift 6 記法・命名規則

## 言語バージョン・設定

```swift
// Package.swift or プロジェクト設定
swiftLanguageVersions: [.v6]
// Swift Strict Concurrency: Complete
```

## 命名規則

### 型・プロトコル
```swift
// PascalCase
struct MakeupProduct {}
final class AdviceViewModel {}
protocol ImagePickerServiceProtocol {}
enum AnalysisState {}
```

### 変数・関数・プロパティ
```swift
// lowerCamelCase
var isLoading: Bool
var makeupProducts: [MakeupProduct]
func fetchRecommendations() async throws -> [Recommendation]
```

### 定数
```swift
// lowerCamelCase（グローバル定数も同じ）
let maxImageSize: CGFloat = 1024
let defaultAnimationDuration: Double = 0.3
// enum namespace で管理する
enum Constants {
    enum Layout {
        static let cornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 20
    }
    enum API {
        static let baseURL = "https://api.example.com/v1"
        static let timeoutInterval: TimeInterval = 30
    }
}
```

### ファイル名
```swift
// 型名と 1:1 対応
HomeView.swift          // struct HomeView
AdviceViewModel.swift   // final class AdviceViewModel
MakeupProduct.swift     // struct MakeupProduct
```

## 型宣言

### struct vs class
```swift
// データモデル・値型 → struct（デフォルト）
struct MakeupProduct: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var brand: String
}

// ViewModel・サービス → final class + @Observable
@Observable
final class HomeViewModel {
    var products: [MakeupProduct] = []
}

// SwiftData モデル → final class + @Model
@Model
final class AdviceHistory {
    var createdAt: Date
    var imageData: Data?
}
```

### プロトコル準拠の順序
```swift
// 1. 継承 2. プロトコル（アルファベット順）
struct Product: Identifiable, Codable, Hashable, Sendable {
    // ...
}
```

## Swift 6 並行処理

### @Observable ViewModel（必須パターン）
```swift
// ObservableObject / @Published は使わない
@Observable
final class AdviceViewModel {
    // @Published 不要 — @Observable が自動追跡
    var analysisState: AnalysisState = .idle
    var recommendations: [Recommendation] = []
    var errorMessage: String?

    func analyze(image: UIImage) async {
        analysisState = .loading
        do {
            recommendations = try await analysisService.analyze(image: image)
            analysisState = .success
        } catch {
            errorMessage = error.localizedDescription
            analysisState = .failure(error)
        }
    }
}
```

### Actor isolation
```swift
// UI 更新は @MainActor
@MainActor
final class AppState {
    var isTabBarVisible: Bool = true
}

// バックグラウンド処理は actor
actor ImageCache {
    private var cache: [String: UIImage] = [:]

    func store(_ image: UIImage, forKey key: String) {
        cache[key] = image
    }

    func image(forKey key: String) -> UIImage? {
        cache[key]
    }
}
```

### async/await パターン
```swift
// ❌ 避ける: DispatchQueue.main.async
// ✅ 使う: await MainActor.run / @MainActor

// Task の起動
func loadData() {
    Task {
        await viewModel.fetchProducts()
    }
}

// .task modifier（推奨）
.task {
    await viewModel.fetchProducts()
}

// 並列実行
async let products = fetchProducts()
async let user = fetchUser()
let (p, u) = try await (products, user)
```

### Sendable
```swift
// 値型は原則 Sendable 準拠
struct Recommendation: Sendable {
    let id: UUID
    let productName: String
    let reason: String
}

// @unchecked Sendable は禁止
// ❌ final class Service: @unchecked Sendable {}
```

## エラーハンドリング

```swift
// typed throws（Swift 6）
enum APIError: Error, LocalizedError {
    case networkUnavailable
    case unauthorized
    case notFound(resource: String)
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: "ネットワークに接続できません"
        case .unauthorized: "認証が必要です"
        case .notFound(let resource): "\(resource) が見つかりません"
        case .serverError(let code): "サーバーエラー (\(code))"
        }
    }
}

// throws(APIError) — typed throws
func fetchProduct(id: UUID) async throws(APIError) -> MakeupProduct {
    // ...
}
```

## Extensions

```swift
// 機能ごとにファイルを分ける
// Extensions/View+Glass.swift
// Extensions/Color+Brand.swift
// Extensions/Date+Formatted.swift

extension View {
    func cardStyle() -> some View {
        self
            .padding(Constants.Layout.cardPadding)
            .glassEffect(.regular, in: .rect(cornerRadius: Constants.Layout.cornerRadius))
    }
}

extension Color {
    static let brandPrimary = Color("BrandPrimary")
    static let brandSecondary = Color("BrandSecondary")
}
```

## Access Control

```swift
// デフォルトは internal（明示不要）
// View から直接アクセスしない ViewModel の実装は private
@Observable
final class HomeViewModel {
    var products: [MakeupProduct] = []        // internal: View が読む
    private var cancellables: Set<AnyCancellable> = []  // private: 外に見せない

    func loadProducts() async { /* ... */ }   // internal: View が呼ぶ
    private func buildRequest() -> URLRequest { /* ... */ }  // private
}
```

## if/switch 式（Swift 5.9+）

```swift
// if 式
let color: Color = if isSelected { .brandPrimary } else { .gray }

// switch 式
let message: String = switch state {
case .idle: "準備完了"
case .loading: "分析中..."
case .success: "完了"
case .failure: "エラーが発生しました"
}
```

## 禁止パターン

```swift
// ❌ ObservableObject
class ViewModel: ObservableObject { @Published var x = 0 }

// ❌ DispatchQueue.main
DispatchQueue.main.async { self.isLoading = false }

// ❌ NavigationView
NavigationView { ... }

// ❌ UIHostingController を乱用
// ❌ @objc / NSObject 継承（SwiftUI 不要なら）
// ❌ force unwrap（!）— guard let / if let を使う
let value = optionalValue!  // 禁止

// ❌ as! キャスト — guard let / if let as? を使う
let vc = viewController as! MyViewController  // 禁止
```
