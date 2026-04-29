# iOS 26 Liquid Glass デザインシステム

## 概要

iOS 26 で導入された Apple の新しいマテリアルシステム。
半透明・屈折・奥行きが動的に変化する素材。
このアプリは **iOS 26 以上のみ**対応のため、Liquid Glass を積極的に使う。

## 基本 API

### glassEffect() — メインモディファイア

```swift
// シグネチャ
func glassEffect<S: Shape>(
    _ glass: Glass = .regular,
    in shape: S,
    isEnabled: Bool = true
) -> some View

// Glass バリアント
.regular  // 標準（ほとんどのケースで使う）
.clear    // よりクリアで透明感が強い（オーバーレイ向け）

// Shape（頻出）
.capsule                      // ピル型ボタン
.circle                       // 丸ボタン・アイコン
.rect(cornerRadius: 16)       // カード・パネル
.ellipse                      // 楕円
```

### 基本使用例

```swift
// ── ボタン
Button("分析する") { /* ... */ }
    .padding(.horizontal, 24)
    .padding(.vertical, 12)
    .glassEffect(.regular, in: .capsule)
    .accessibilityIdentifier("advice_analyze_button")

// ── カード
VStack {
    Text("おすすめアイテム")
    // コンテンツ
}
.padding(20)
.glassEffect(.regular, in: .rect(cornerRadius: 20))

// ── アイコンボタン
Button {
    // action
} label: {
    Image(systemName: "camera.fill")
        .font(.title2)
        .padding(12)
}
.glassEffect(.regular, in: .circle)
.accessibilityIdentifier("advice_camera_button")
```

## GlassEffectContainer

複数の Glass 要素を 1 つのコンテナに収め、モーフィング遷移を可能にする。

```swift
// ツールバーなど複数ボタンが並ぶ場合
GlassEffectContainer {
    HStack(spacing: 0) {
        Button("肌質") { selectedTab = .skin }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffectID("tab_skin", in: namespace)

        Button("目元") { selectedTab = .eyes }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffectID("tab_eyes", in: namespace)

        Button("リップ") { selectedTab = .lips }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffectID("tab_lips", in: namespace)
    }
}
.glassEffect(.regular, in: .capsule)
```

## マテリアル階層（背景素材）

Glass の背後に差し込む素材。用途別に選択:

```swift
// 最薄（最も透明）
.background(.ultraThinMaterial)

// 標準
.background(.regularMaterial)

// 濃い
.background(.thickMaterial)

// ナビゲーションバー・タブバー用
.background(.bar)
```

## デザインルール

### ✅ やるべきこと

```swift
// 1. glassEffect は修飾子チェーンの「最後」に置く
Text("タイトル")
    .font(.headline)
    .padding()
    .glassEffect(.regular, in: .capsule)  // 最後

// 2. 画像背景の上に Glass を重ねる（効果が映える）
ZStack {
    Image("background_skin")
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

    VStack {
        // コンテンツ
    }
    .glassEffect(.regular, in: .rect(cornerRadius: 20))
}

// 3. isEnabled で条件付き適用
.glassEffect(.regular, in: .capsule, isEnabled: isAvailable)

// 4. 浮いているコントロール（FAB等）に Glass を使う
VStack {
    Spacer()
    HStack {
        Spacer()
        Button {
            showCamera = true
        } label: {
            Image(systemName: "camera.viewfinder")
                .font(.title)
                .padding(20)
        }
        .glassEffect(.regular, in: .circle)
        .accessibilityIdentifier("home_fab_camera")
        .padding(24)
    }
}
```

### ❌ やってはいけないこと

```swift
// ❌ Glass の上に Glass を重ねない（視覚的に崩れる）
VStack {
    innerCard  // .glassEffect 付き
}
.glassEffect(.regular, in: .rect(cornerRadius: 20))  // NG: ネスト

// ❌ 背景が単色の場合に使わない（効果が出ない）
// solid white background の上に Glass は意味がない

// ❌ テキスト可読性を損なう使い方
// Glass + 白文字 + 白い背景 = 読めない
// → 必ず十分なコントラストを確保する

// ❌ .clear Glass をそのまま使わない（背景を暗くする層を追加する）
// ✅ .clear Glass + dimming layer
Color.black.opacity(0.4)
    .ignoresSafeArea()
    .overlay {
        ModalCard()
            .glassEffect(.clear, in: .rect(cornerRadius: 24))
    }
```

## カラーシステム（Liquid Glass 対応）

```swift
// Assets.xcassets/Colors/ に定義
// Light / Dark 両対応で設定すること

extension Color {
    // ブランドカラー
    static let brandPrimary   = Color("BrandPrimary")    // 例: 深いネイビー系
    static let brandSecondary = Color("BrandSecondary")  // 例: ゴールド系

    // Glass 上のテキスト（可読性確保）
    static let glassLabel     = Color("GlassLabel")      // white/black 自動
    static let glassLabelSub  = Color("GlassLabelSub")   // 60% opacity
}
```

## タイポグラフィ（Glass 上）

```swift
// Glass 上では font weight を上げて可読性を確保
Text("製品名")
    .font(.headline)          // medium 以上推奨
    .fontWeight(.semibold)
    .foregroundStyle(.primary)

// 補足テキスト
Text("説明文")
    .font(.subheadline)
    .foregroundStyle(.secondary)  // 自動でシステム適応

// ❌ Glass 上での .tertiary は避ける（コントラスト不足）
```

## アニメーション

```swift
// Glass 要素の表示/非表示
.animation(.spring(duration: 0.4, bounce: 0.2), value: isVisible)

// モーフィング（GlassEffectContainer 内）
withAnimation(.spring(duration: 0.35)) {
    selectedTabID = newTab
}

// スクロール連動でのスケール変化
.scaleEffect(isScrolledDown ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.2), value: isScrolledDown)
```

## コンポーネントテンプレート

### GlassCard

```swift
// Shared/Views/Components/GlassCard.swift
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(20)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

// 使用
GlassCard {
    VStack(alignment: .leading, spacing: 8) {
        Text("製品名").font(.headline)
        Text("ブランド").font(.subheadline).foregroundStyle(.secondary)
    }
}
```

### GlassPrimaryButton

```swift
// Shared/Views/Buttons/GlassPrimaryButton.swift
struct GlassPrimaryButton: View {
    let title: String
    let icon: String?
    let accessibilityID: String
    let action: () async -> Void
    @State private var isPressed = false

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
        .glassEffect(.regular, in: .capsule)
        .accessibilityIdentifier(accessibilityID)
    }
}
```
