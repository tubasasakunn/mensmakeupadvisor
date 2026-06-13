# swift-base

iOS / SwiftUI アプリを「コーディング規約 → ビルド検証 → 意思決定の記録 →
App Store 提出メタデータの自動反映 → ストア用スクショ生成 → SNS カルーセル投稿」まで
一貫して回すための再利用テンプレート。新規アプリのリポジトリにそのままコピーして使う。

実在アプリの運用から抽出したエッセンスを、アプリ固有値を 1 ファイル
（`appstore.config.json`）に外出しして汎用化したもの。

## 何が入っているか

| 領域 | 場所 | 概要 |
|---|---|---|
| 中央設定 | `appstore.config.json` | アプリ名・bundle id・scheme・ブランド色など。**最初にここを書き換える** |
| Claude 用ガイド | `CLAUDE.md` | コードを触るときの罠と各正本への入口（テンプレ） |
| 初回手順 | `SETUP.md` | コピー後にやることを上から順に |
| コーディング規約 | `.claude/rules/` | Swift 規約・並行性規約（Swift を触ると自動読み込み） |
| スキル | `.claude/skills/` | `/verify-build` `/audit-conventions` `/adr` `/release-assets` `/sns-post` |
| 意思決定の記録 | `docs/adr/` | ADR の template と運用ルール |
| 提出パイプライン | `scripts/` `fastlane/` `.github/workflows/` | release/** push で App Store Connect へメタデータ・スクショを自動反映 |
| ストアメタデータ | `release/<version>/` | 文字数チェック付きの .txt・rating.json・img/ |
| スクショ素材 | `material/` | クロマキー(#00FF00)方式の画面素材・フッテージ |
| ストア画像生成 | `scripts/make_store_images.py` + `scripts/store_slides.json` | モック合成・見出し焼き込み |
| SNS カルーセル | `post/` | TikTok / Lemon8 の複数画像投稿エンジン |

## クイックスタート

```bash
# 1. このディレクトリの中身を新規アプリのリポジトリ直下へコピー
# 2. appstore.config.json の値を全部実アプリのものに置き換える
# 3. 以降は SETUP.md を上から
```

詳細は **`SETUP.md`**。

## 設計の前提

- **集約レイヤを必ず通す**規約（色・文字列・日付・キーを直書きしない）。`/audit-conventions` で機械点検。
- **Swift 5 言語モード + approachable concurrency + MainActor デフォルト隔離**を推奨。
- **App Store メタデータは Git 管理 → CI で自動反映**（バイナリと審査提出は手動）。
- **ストア画像・SNS 画像はコードで生成**（クロマキー合成 + 見出し焼き込み）。ブランドは config 集約。
- **意思決定は ADR に残す**（なぜそうしたか・却下案・再考の条件）。

## 依存

- App Store CI：Ruby（fastlane）。ローカルは `bundle install`。
- 画像生成：Python 3 + `Pillow` `numpy`。見出しフォントは Noto（OFL）を実行時取得。
- ビルド検証：macOS + Xcode。

## カスタマイズの勘所

- アイコングリフ（`make_store_images.py` / `post/_brand.py` の `icon_glyph`）は
  角丸スクエア＋頭文字のプレースホルダ。実アプリのロゴ／マスコットに差し替える。
- ストアのスライド構成は `scripts/store_slides.json`、SNS の投稿定義は
  `post/build_posts.py` / `post/build_index.py`。
- ロケールは `appstore.config.json` の `primary_locale`（既定 `ja`）。
