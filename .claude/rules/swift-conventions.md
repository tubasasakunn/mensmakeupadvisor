---
paths:
  - "**/*.swift"
---

# Swift コーディング規約

新しい Swift / SwiftUI アプリで一貫した品質を保つための骨子。
コードを書く・直すときはこの規約に揃える。新しいパターンを導入したくなったら、
まず既存コードに前例がないか探すこと。違反の全走査は `/audit-conventions`。

> このテンプレートは「集約レイヤを必ず通す」設計を前提にしている。新規プロジェクトでは
> 早い段階で以下の集約ファイルを作っておく（無ければ作ってから使う）。

## 集約レイヤを必ず通す

| 何を書くとき | 通す場所（推奨ファイル） | 直書きの例（禁止） |
|---|---|---|
| 色・余白・角丸・サイズ・フォント | `Tokens.*`（`Design/DesignTokens.swift`） | `.padding(16)` / `.frame(width: 44)` / `Font.custom(...)` |
| ユーザー向け文字列 | `Strings.*`（`Resources/Strings.swift`） | `Text("完了")` |
| 日付の表示フォーマット | `DisplayDate.*`（`Resources/DateFormatters.swift`） | ビュー内で `DateFormatter()` を生成 |
| `@AppStorage` / UserDefaults キー | `AppStorageKeys.*` | `@AppStorage("someKey")` |
| ハプティクス | `Haptics.*`（`Design/Haptics.swift`） | `UIImpactFeedbackGenerator` 直叩き |
| ディープリンク構成要素 | `DeepLink`（`AppNavigator.swift`） | `url.scheme == "..."` の直比較 |

- 集約先に欲しい定数が無ければ**先に定数を足してから**使う。意味の違う既存定数の
  流用（別画面用の文言を借りる等）はしない。
- 例外：別ターゲット（ウィジェット拡張等）からは本体の `Tokens` / `Strings` が
  見えないため、拡張内のリテラルは許容（コメントで対応元を示す）。

## 安全性

- **強制アンラップ `!` 禁止**。`guard let` / `if let` で逃がす。
  例外は `layerClass` オーバーライド済みビューの `layer as!`（型が構造的に保証される）等、
  構造で保証できる箇所のみ（理由コメント必須）。
- **`fatalError` は最後の砦**。永続化スタックの起動時フォールバック最終段のような
  「ここまで来たら継続不能」な箇所だけ。それ以外は `Logger` でログ + early return。
- **エラーを握りつぶさない**。`try?` を使ってよいのは「失敗しても続行が正しい」と
  コメントで説明できる箇所だけ。保存・生成系の失敗は必ず `Logger` に残す
  （`privacy:` 指定を忘れない）。`print()` は使わない。
- SwiftData + CloudKit ミラーリングを使うなら：モデルに `@Attribute(.unique)` を
  使わない（CloudKit 非互換。一意性は upsert で担保）。新フィールドは optional か
  デフォルト値付き。長い `await` を跨いだモデル書き込みの前は主キーで refetch する
  （ゾンビ書き込みクラッシュ防止）。判断したら ADR に残す。

## 構造

- 新規の参照型は `@Observable`。`ObservableObject` / `@Published` / `@StateObject` は使わない。
  所有は `@State`、共有は `@Environment`、受け取りは素の `let`。
- ファイルは **500 行を超えたら分割を検討**。
- ビューの分割は「computed property で body を返す」より「サブビュー struct の抽出」を優先
  （Instruments の SwiftUI 計測で原因追跡できる単位になる）。
- 触ったファイルに `// MARK: -` 区分けが無ければ追加する。
- Xcode の `PBXFileSystemSynchronizedRootGroup` を採用しているプロジェクトでは
  `.swift` を増やすだけでターゲットに入る（`pbxproj` 編集不要・してはならない）。
  ファイルを**削除**したら `git status` の `deleted:` を必ず確認する
  （「ファイルだけ消えてビルドが直る」静かな事故が起きやすい）。

## スタイル

- `!(x?.isEmpty ?? true)` のような二重否定は `x?.isEmpty == false` と書く。
- `.onChange(of:)` で新旧値を使わないときは引数なしクロージャ形式（iOS 17+）を使う。
- `DispatchQueue.main.async` を書かない。`@MainActor` 文脈の 1 ターン遅延は `Task { }` で足りる。

## コメント

- 「なぜそうなっているか」を書く。何をしているかは命名で表す。
- 仕様の根拠は仕様書のセクション番号、設計判断の経緯は `docs/adr/NNNN` を引用する。
- 一見「統一できそうで統一してはいけない」コードには、その旨のコメントを必ず残す。

## 変更を確定する前に

1. macOS 環境なら `/verify-build` でビルド検証（`.swift` 由来 warning/error = 0 を維持）。
   ビルドできない環境では diff 全体のコンパイル整合性レビューで代替し、その旨を明記する。
2. `/audit-conventions` で規約違反の混入をチェック。
3. アーキテクチャ・データモデル・依存・並行性の判断をしたら `/adr` で記録する。
