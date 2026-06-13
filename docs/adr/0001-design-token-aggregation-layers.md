# 0001. デザイントークンを集約レイヤ (Theme.Typography / Theme.Size) に必ず通す

- Status: Accepted
- Date: 2026-06-14

## 文脈（Context）

`.claude/rules/swift-conventions.md` は「色・余白・角丸・サイズ・フォントは集約レイヤ
（Tokens）を必ず通す」を骨子に掲げているが、実コードには直書きが多数残っていた。

- フォント `.font(.system(size:...))` … 287 箇所（集約層が存在しなかった）
- frame サイズ `.frame(width: 44)` 等 … 61 箇所（同上）
- 描画ストローク幅 `lineWidth: 0.5` 等 … 53 箇所（同上）

色 (`Theme`) と余白/角丸 (`Theme.Spacing` / `Theme.Radius`) は既に集約されていたが、
フォント・固定サイズ・線幅には集約層が無く、デザイン変更が全ファイル横断になっていた。

## 決定（Decision)

フォントと固定サイズ・線幅に専用のトークン層を新設し、View からの直書きを禁止する。

- `Shared/Theme/Typography.swift` … `Theme.Typography`。UI（既定 design）/ Data（monospaced）
  / Display（serif）の 3 ファミリ・約 100 トークン。
- `Shared/Theme/Size.swift` … `Theme.Size`。Stroke / Dot / Control / Column / ShareCard /
  Canvas / Line のスケール。
- **値は現行のデザインを 1:1 で保持**（純粋なリファクタ。視覚は変えない）。px を整える
  「正規化」はデザインレビューを要するため本決定の対象外とした。
- 1 箇所でしか使わない内在的寸法（特定コンポーネントの縦横比など）はグローバルトークンに
  出さず、各ファイルの `private enum Layout` に閉じ込める。

## 却下した代替案（Alternatives）

- **意味スケールへ正規化（17→18 等に丸める）** — 設計的には綺麗だが、出荷中アプリの
  見た目が変わる＝デザイン変更でありリファクタの範疇を超える。視覚レビューが要る。
- **全リテラルを 1 ファイルの巨大 enum に機械集約（コンテンツ文字列含む）** — Onboarding /
  Tutorial / Score のコンテンツは既に専用 `Models/` ファイルに集約済みで、そこへ寄せると
  逆に保守性が落ちる。コンテンツデータと UI トークンは別物として扱う。
- **padding / spacing / cornerRadius も同時に集約** — 既存 `Theme.Spacing`（8pt: 4/8/12/16/20/28/40/56）
  が実使用値（24 が 45 回、10/14/6 等）をカバーしておらず、現値保持での集約には
  スケール再設計が要る。既存トークン名（xs..huge）への影響も大きいため別 ADR に切り出す。

## 帰結（Consequences）

- 得たもの：フォント・サイズ・線幅の変更が 1 ファイルに局所化。`/audit-conventions` に
  `\.system\(size:` / `lineWidth:\s*\d` パターン（#13/#14）を追加し増分を検知できる。
- 払ったコスト：トークン数が多い（現値保持のため combo を温存）。意味スケールほど整っていない。
- 残課題：padding / spacing / cornerRadius は未集約（audit skill に明記）。

## 再考の条件（Revisit when）

- ライト/ダーク両対応やアクセシビリティ（Dynamic Type）対応が要件化したとき
  → 固定 px を捨て、SwiftUI 標準の意味フォント／相対サイズへ寄せる正規化を検討する。
- padding / spacing のスケール再設計を決めたとき → 本 ADR にトークン体系を揃える。
