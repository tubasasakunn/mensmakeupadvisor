# E2E テスト — Maestro + アクセシビリティ ID + モックモード

## 基本方針

**新しい画面を作るたびに、その画面への遷移と主要操作をカバーする Maestro フローを作成する。**

```
.maestro/
├── flows/
│   ├── home_flow.yaml         # ホーム画面
│   ├── advice_flow.yaml       # アドバイス（メイン機能）
│   ├── history_flow.yaml      # 履歴
│   ├── products_flow.yaml     # 製品一覧・詳細
│   └── profile_flow.yaml      # プロフィール・設定
└── utils/
    └── setup.yaml             # 共通セットアップ（ログインなど）
```

## アクセシビリティ ID 命名規則

### フォーマット
```
<screen>_<element>_<type>
```

### 例
```swift
// ホーム画面
"home_tab"                    // タブバーボタン
"home_fab_camera"             // フローティングアクションボタン
"home_product_list"           // 製品一覧 ScrollView/List
"home_product_card_\(id)"     // 個別カード

// アドバイス画面
"advice_image_picker"         // 画像選択エリア
"advice_camera_button"        // カメラボタン
"advice_analyze_button"       // 分析開始ボタン
"advice_loading_indicator"    // ローディング表示
"advice_recommendation_list"  // 結果リスト

// 履歴画面
"history_list"
"history_row_\(id)"

// ナビゲーション
"nav_back_button"
"nav_settings_button"
```

### Swift 側の付与ルール

```swift
// ✅ 全てのボタン・リンク・インタラクティブ要素に付与
Button("分析する") { /* */ }
    .accessibilityIdentifier("advice_analyze_button")

// ✅ リスト・ScrollView にも付与
List(recommendations) { rec in
    RecommendationRow(item: rec)
        .accessibilityIdentifier("advice_recommendation_\(rec.id)")
}
.accessibilityIdentifier("advice_recommendation_list")

// ✅ タブ
Tab("ホーム", systemImage: "house.fill") {
    HomeView()
}
.accessibilityIdentifier("tab_home")

// ✅ テキストフィールド
TextField("名前", text: $name)
    .accessibilityIdentifier("profile_name_field")

// ✅ Toggle / Picker
Toggle("通知を受け取る", isOn: $notificationsEnabled)
    .accessibilityIdentifier("settings_notifications_toggle")

// helper extension を使う
extension View {
    func aid(_ id: String) -> some View {
        accessibilityIdentifier(id)
    }
}
// Button(...).aid("advice_analyze_button")
```

## モックモード（自動化困難な機能の対応）

カメラ・画像ピッカー・生体認証など Maestro が直接操作できない機能は
**モックモードフラグ** で自動的にダミーデータに差し替える。

### フラグ定義

```swift
// Core/Utilities/AppEnvironment.swift
enum AppEnvironment {
    // ✅ Launch Argument でフラグを受け取る
    static var isMockMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-mode")
    }

    // 個別のモックフラグ
    static var useMockImagePicker: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-image-picker")
    }

    static var useMockCamera: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-camera")
    }

    static var useMockAuth: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-auth")
    }
}
```

### 画像ピッカーのモック化

```swift
// Features/Advice/Components/ImagePickerCard.swift
struct ImagePickerCard: View {
    @Binding var selectedImage: UIImage?
    let onCapture: (UIImage) -> Void

    // モックモードではデフォルト画像を自動選択
    private let mockImages: [String] = [
        "mock_face_1",   // Assets.xcassets に用意
        "mock_face_2",
        "mock_face_3"
    ]
    @State private var selectedMockIndex = 0

    var body: some View {
        if AppEnvironment.useMockImagePicker {
            mockImagePickerView
        } else {
            realImagePickerView
        }
    }

    // Maestro からタップ可能なモックUI
    private var mockImagePickerView: some View {
        VStack(spacing: 12) {
            // 現在選択中のモック画像を表示
            if let imageName = mockImages[safe: selectedMockIndex],
               let mockImage = UIImage(named: imageName) {
                Image(uiImage: mockImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .accessibilityIdentifier("advice_mock_preview_image")
            }

            // モック画像を切り替えるボタン群
            HStack(spacing: 8) {
                ForEach(mockImages.indices, id: \.self) { index in
                    Button("画像\(index + 1)") {
                        selectedMockIndex = index
                        if let name = mockImages[safe: index],
                           let img = UIImage(named: name) {
                            selectedImage = img
                            onCapture(img)
                        }
                    }
                    .glassEffect(.regular, in: .capsule)
                    .accessibilityIdentifier("advice_mock_image_\(index)")
                }
            }

            Text("[MOCK] 画像ピッカー")
                .font(.caption)
                .foregroundStyle(.orange)
                .accessibilityIdentifier("advice_mock_mode_label")
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }

    private var realImagePickerView: some View {
        // 本番の PHPickerViewController / Camera
        // ...
    }
}
```

### Service レイヤーのモック注入

```swift
// mensmakeupadvisorApp.swift
@main
struct mensmakeupadvisorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.analysisService, resolvedAnalysisService)
                .environment(\.productService, resolvedProductService)
        }
        .modelContainer(sharedModelContainer)
    }

    private var resolvedAnalysisService: any AnalysisServiceProtocol {
        AppEnvironment.isMockMode ? MockAnalysisService() : AnalysisService()
    }

    private var resolvedProductService: any ProductServiceProtocol {
        AppEnvironment.isMockMode ? MockProductService() : ProductService()
    }
}
```

### MockAnalysisService の実装テンプレート

```swift
// Mocks/MockAnalysisService.swift
final class MockAnalysisService: AnalysisServiceProtocol, Sendable {
    // テスト用固定レスポンス（即座に返す）
    func analyze(image: UIImage) async throws -> AnalysisResult {
        // 少し待って「分析中」UIをテストできるようにする
        try await Task.sleep(for: .seconds(1.5))
        return AnalysisResult(
            skinType: .combination,
            recommendations: Recommendation.mocks
        )
    }
}

// Mocks/MockData/Recommendation+Mock.swift
extension Recommendation {
    static var mocks: [Recommendation] {
        [
            Recommendation(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                productName: "BBクリーム（モック）",
                brand: "テストブランド",
                reason: "混合肌に適した保湿成分配合",
                category: .base
            ),
            Recommendation(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                productName: "眉マスカラ（モック）",
                brand: "テストブランド2",
                reason: "自然な仕上がりで初心者向け",
                category: .eyebrow
            )
        ]
    }
}
```

## Maestro フロー テンプレート

### 基本フォーマット（.maestro/flows/advice_flow.yaml）

```yaml
appId: com.yourteam.mensmakeupadvisor
---
# アドバイス画面 E2E フロー
# 前提: --mock-image-picker --mock-mode の Launch Arguments が付いていること

- launchApp:
    arguments:
      - "--mock-mode"
      - "--mock-image-picker"

# ── タブ遷移でアドバイス画面を開く
- tapOn:
    id: "tab_advice"

- assertVisible:
    id: "advice_image_picker"

# ── モック画像 1 を選択
- tapOn:
    id: "advice_mock_image_0"

- assertVisible:
    id: "advice_mock_preview_image"

# ── 分析ボタンをタップ
- tapOn:
    id: "advice_analyze_button"

# ── ローディング表示を確認
- assertVisible:
    id: "advice_loading_indicator"

# ── 結果リストが表示されるまで待機（最大 10 秒）
- waitForAnimationToEnd:
    timeout: 10000

- assertVisible:
    id: "advice_recommendation_list"

# ── 最初の推薦アイテムをタップ（詳細画面へ遷移）
- tapOn:
    id: "advice_recommendation_0"

- assertVisible:
    id: "product_detail_title"

# ── 戻る
- tapOn:
    id: "nav_back_button"

- assertVisible:
    id: "advice_recommendation_list"
```

### ホーム画面フロー（.maestro/flows/home_flow.yaml）

```yaml
appId: com.yourteam.mensmakeupadvisor
---
- launchApp:
    arguments:
      - "--mock-mode"

- assertVisible:
    id: "tab_home"

- scrollDown:
    on:
      id: "home_product_list"

- tapOn:
    id: "home_product_card_0"

- assertVisible:
    id: "product_detail_title"

- tapOn:
    id: "nav_back_button"
```

### セットアップユーティリティ（.maestro/utils/setup.yaml）

```yaml
# 共通セットアップ（必要な場合）
appId: com.yourteam.mensmakeupadvisor
---
- launchApp:
    clearState: true
    arguments:
      - "--mock-mode"
      - "--mock-auth"
      - "--mock-image-picker"
```

## Maestro 実行方法

```bash
# 単一フローを実行
maestro test .maestro/flows/advice_flow.yaml

# 全フローを実行
maestro test .maestro/flows/

# デバッグ（スクリーンショット付き）
maestro test --format junit .maestro/flows/advice_flow.yaml
```

## 新画面追加時の E2E チェックリスト

新しい `<Feature>View` を作成したら以下を必ず実施:

```
[ ] 全ボタン・タップ要素に .accessibilityIdentifier("<screen>_<element>_<type>") を付与
[ ] 全リスト・ScrollView に .accessibilityIdentifier() を付与
[ ] 自動化困難な機能（カメラ/画像/生体認証）は AppEnvironment.useMock* フラグを追加
[ ] Mocks/ に MockXxxService を作成または既存を更新
[ ] Mocks/MockData/ に <Model>+Mock.swift を作成
[ ] .maestro/flows/<featurename>_flow.yaml を作成
    - launchApp（--mock-mode 引数付き）
    - 画面への遷移
    - 主要操作（ハッピーパス）
    - 結果の assertVisible
    - 戻る操作
[ ] maestro test で実際に通ることを確認してからコミット
```

## Collection の safe subscript（クラッシュ防止）

```swift
// Shared/Extensions/Collection+Safe.swift
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
```
