# MensMakeupAdvisor — Claude Rules

## プロジェクト概要

メンズメイクアップアドバイザーアプリ。Swift 6 + SwiftUI + SwiftData で構築。
最小デプロイターゲット: **iOS 26**（Liquid Glass デザイン前提）

## ルールファイル一覧

詳細ルールは `.claude/rules/` に格納:

| ファイル | 内容 |
|---|---|
| [swift-conventions.md](.claude/rules/swift-conventions.md) | Swift 6 記法・命名規則・並行処理 |
| [swiftui-patterns.md](.claude/rules/swiftui-patterns.md) | SwiftUI アーキテクチャ・状態管理 |
| [liquid-glass.md](.claude/rules/liquid-glass.md) | iOS 26 Liquid Glass デザインシステム |
| [project-structure.md](.claude/rules/project-structure.md) | ディレクトリ構成・ファイル配置 |
| [testing-e2e.md](.claude/rules/testing-e2e.md) | Maestro E2E・アクセシビリティID・モックモード |

## 絶対に守るルール（全ファイル共通）

1. **Swift 6 strict concurrency** — `@unchecked Sendable` 禁止。コンパイラ警告を全て解消すること
2. **iOS 26 以上** — 古い API（`ObservableObject`, `@Published`, `NavigationView`）は使わない
3. **新規画面を作ったら必ず Maestro フローを作成** — `.maestro/<FeatureName>/` に配置
4. **全インタラクティブ要素に `.accessibilityIdentifier()` を付与** — Maestro テストのため
5. **SwiftData のみ** — CoreData は使わない
6. **コメントは "なぜ" だけ** — 何をするかは書かない。自明なコードにコメント不要
7. **Preview は必ずインメモリ ModelContainer を使う**

## アーキテクチャの設計判断

### 画面遷移は NavigationStack ではなく AppScreen + NavigationContext

swiftui-patterns.md は NavigationStack を推奨しているが、本プロジェクトは
**意図的に NavigationStack を採用していない**。

- 全画面が編集者風のクロスフェード遷移で繋がる UX を保つため (`.transition(.opacity)`)
- 同じ画面 (capture / studio / diagnosis) を複数の入口から開けるよう、
  画面遷移と並行して `captureOrigin` / `studioOrigin` / `diagnosisOrigin` の
  origin breadcrumb を更新するため。NavigationStack の `path` だけでは
  「Home から来た studio は Home に戻り、Diagnosis から来た studio は Diagnosis に戻る」
  という挙動を素直に表現しにくい
- 一部画面 (Tutorial / Onboarding) は内側で独自のスワイプ UI を持つため、
  iOS 標準の back gesture と衝突しやすい

新規画面を追加する場合:
- `AppScreen` に case を足し、`RootView` の switch に対応する View を追加
- 遷移は `appState.navigation.navigate(to:)` か router ヘルパー
  (`openCapture(from:)` / `openDiagnosis(from:)` / `openStudio(back:)` /
  `openTutorial(studioBack:)` / `openHome(tab:)`) を使う
- origin の付け忘れを防ぐため、生 `navigate(to:)` ではなくヘルパーを優先

### 状態は AppState ファサード経由でサブ状態にアクセス

AppState は composition root として 3 つの `@Observable` サブ状態を保持する:

| サブ状態 | 責務 |
|---|---|
| `NavigationContext` | 画面遷移、origin breadcrumbs、router ヘルパー |
| `MakeupSession` | 撮影画像 / 解析結果 / composition / MakeupEngine |
| `AppFlowState` | フローフラグ (tutorialStep, skipDiagnosisOnNextFlow 等) |

3 つとも個別に Environment 注入されているので、
新規 View は `@Environment(NavigationContext.self) private var navigation` のように
焦点を絞った依存を持つこと。`@Environment(AppState.self)` の全体依存は
既存コードの後方互換用に残しているフォワードプロパティ。
