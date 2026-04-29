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
