# プロジェクト構成・ファイル配置ルール

## ディレクトリ構造（完全版）

```
mensmakeupadvisor/
├── mensmakeupadvisorApp.swift      # @main エントリポイント
├── App/
│   ├── RootView.swift              # TabView + NavigationStack
│   ├── AppRouter.swift             # 型安全ナビゲーション
│   └── AppState.swift              # @MainActor グローバル状態
│
├── Features/                       # 機能モジュール（画面単位）
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── Components/
│   │   │   ├── ProductHighlightCard.swift
│   │   │   └── TodaysTipsSection.swift
│   │   └── Models/
│   │       └── HomeSection.swift
│   │
│   ├── Advice/                     # メイクアドバイス（AI分析）
│   │   ├── AdviceView.swift
│   │   ├── AdviceViewModel.swift
│   │   ├── Components/
│   │   │   ├── ImagePickerCard.swift
│   │   │   ├── AnalysisLoadingView.swift
│   │   │   └── RecommendationList.swift
│   │   └── Models/
│   │       ├── AnalysisResult.swift
│   │       └── Recommendation.swift
│   │
│   ├── History/                    # 履歴
│   │   ├── HistoryView.swift
│   │   ├── HistoryViewModel.swift
│   │   └── Components/
│   │       └── HistoryRowView.swift
│   │
│   ├── Products/                   # 製品一覧・詳細
│   │   ├── ProductListView.swift
│   │   ├── ProductDetailView.swift
│   │   ├── ProductListViewModel.swift
│   │   └── Components/
│   │       └── ProductCard.swift
│   │
│   └── Profile/                    # プロフィール・設定
│       ├── ProfileView.swift
│       ├── ProfileViewModel.swift
│       └── SettingsView.swift
│
├── Core/                           # アプリ横断の基盤
│   ├── Services/
│   │   ├── AnalysisService.swift   # AI画像分析
│   │   ├── ProductService.swift    # 製品データ
│   │   └── AuthService.swift
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── APIEndpoints.swift
│   │   └── NetworkError.swift
│   ├── Database/
│   │   ├── Models/
│   │   │   ├── AdviceHistory.swift  # @Model
│   │   │   ├── FavoriteProduct.swift
│   │   │   └── UserProfile.swift
│   │   └── DatabaseService.swift
│   ├── Environment/
│   │   └── ServiceKeys.swift       # EnvironmentKey 定義
│   └── Utilities/
│       ├── Logger.swift
│       ├── ImageResizer.swift
│       └── Haptics.swift
│
├── Shared/                         # 再利用 UI コンポーネント
│   ├── Views/
│   │   ├── Buttons/
│   │   │   ├── GlassPrimaryButton.swift
│   │   │   ├── GlassSecondaryButton.swift
│   │   │   └── GlassIconButton.swift
│   │   ├── Cards/
│   │   │   └── GlassCard.swift
│   │   ├── States/
│   │   │   ├── LoadingView.swift
│   │   │   ├── EmptyStateView.swift
│   │   │   └── ErrorStateView.swift
│   │   └── Modifiers/
│   │       ├── CardStyleModifier.swift
│   │       └── GlassBackgroundModifier.swift
│   ├── Extensions/
│   │   ├── View+Accessibility.swift
│   │   ├── View+GlassStyle.swift
│   │   ├── Color+Brand.swift
│   │   ├── Image+Resize.swift
│   │   └── Date+Formatted.swift
│   └── Constants/
│       └── Constants.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── AppIcon.appiconset/
│   │   ├── Colors/
│   │   │   ├── BrandPrimary.colorset/
│   │   │   ├── BrandSecondary.colorset/
│   │   │   ├── GlassLabel.colorset/
│   │   │   └── GlassLabelSub.colorset/
│   │   ├── Icons/
│   │   └── Illustrations/
│   ├── Localizable.xcstrings        # iOS 16+ 形式（.xcstrings）
│   └── Fonts/
│
├── Mocks/                           # テスト・Preview 用モック
│   ├── MockAnalysisService.swift
│   ├── MockProductService.swift
│   ├── MockData/
│   │   ├── MakeupProduct+Mock.swift
│   │   └── Recommendation+Mock.swift
│   └── MockImagePickerService.swift
│
└── .maestro/                        # E2E テストフロー（下記参照）
    ├── flows/
    │   ├── home_flow.yaml
    │   ├── advice_flow.yaml
    │   ├── history_flow.yaml
    │   └── profile_flow.yaml
    └── utils/
        └── setup.yaml
```

## ファイル配置ルール

### どこに何を置くか

| ファイルの種類 | 配置場所 | 命名 |
|---|---|---|
| 画面全体の View | `Features/<Feature>/` | `<Feature>View.swift` |
| その画面専用の ViewModel | `Features/<Feature>/` | `<Feature>ViewModel.swift` |
| その画面専用のサブコンポーネント | `Features/<Feature>/Components/` | `<ComponentName>.swift` |
| その画面固有のモデル（DTO等） | `Features/<Feature>/Models/` | `<ModelName>.swift` |
| 複数画面で使う UI | `Shared/Views/` | 用途がわかる名前 |
| View の extension | `Shared/Extensions/` | `<Type>+<Purpose>.swift` |
| SwiftData モデル | `Core/Database/Models/` | `<ModelName>.swift`（`@Model` 付き） |
| サービス（API, DB 操作） | `Core/Services/` | `<Name>Service.swift` |
| EnvironmentKey | `Core/Environment/ServiceKeys.swift` | 1ファイルに集約 |
| テスト用モック | `Mocks/` | `Mock<ServiceName>.swift` |
| Maestro E2E フロー | `.maestro/flows/` | `<screen>_flow.yaml` |

## 命名規則（ファイル・型）

```
View      → <Feature>View.swift         → struct HomeView
ViewModel → <Feature>ViewModel.swift    → final class HomeViewModel
Model     → <ModelName>.swift           → struct MakeupProduct
Service   → <Name>Service.swift         → final class AnalysisService
Protocol  → <Name>ServiceProtocol       → (ファイル内 or ServiceKeys.swift に同居)
Extension → <Type>+<Purpose>.swift      → View+Accessibility.swift
Mock      → Mock<Name>.swift            → MockAnalysisService.swift
```

## 新機能追加チェックリスト

新しい画面・機能を追加するときは以下を全て実施する:

```
[ ] Features/<FeatureName>/ ディレクトリを作成
[ ] <FeatureName>View.swift を作成
[ ] <FeatureName>ViewModel.swift を作成（@Observable final class）
[ ] 全インタラクティブ要素に .accessibilityIdentifier() を付与
[ ] AppRouter.Destination に遷移先を追加
[ ] RootView の navigationDestination に case を追加
[ ] Mocks/Mock<Service>.swift を作成（画像選択など自動化困難な機能）
[ ] .maestro/flows/<featurename>_flow.yaml を作成
[ ] #Preview を作成（インメモリ ModelContainer + MockService）
```

## インポート順序（各ファイル）

```swift
// 1. Apple フレームワーク（アルファベット順）
import Foundation
import SwiftData
import SwiftUI
import UIKit

// 2. サードパーティ（アルファベット順）
import Lottie

// 3. 自作モジュール（Xcode Package の場合）
```

## ファイル内の構造順序

```swift
// 1. import
// 2. 型宣言
struct AdviceView: View {

    // 3. MARK: - Properties（State, Binding, Environment 等）
    @State private var viewModel = AdviceViewModel()
    @Environment(\.modelContext) private var modelContext

    // 4. MARK: - Body
    var body: some View { ... }

    // 5. MARK: - Subviews（private computed property）
    private var headerSection: some View { ... }

    // 6. MARK: - Methods
    private func handleTap() { ... }
}

// 7. Preview（ファイル末尾）
#Preview { ... }
```
