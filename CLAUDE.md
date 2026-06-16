# CLAUDE.md

このリポジトリで Claude Code として作業するときの「次に開いたら最短で動ける」ガイド。
**これは swift-base テンプレート由来**。新しいアプリにコピーしたら、まず
`appstore.config.json` の値を全部置き換え、このファイルのプレースホルダ（`<...>`）を実情に合わせる。

設計判断の経緯（なぜそうしたか・何を却下したか）は `docs/adr/` を正本とする。
コーディング規約・並行性規約は `.claude/rules/`（Swift ファイルを触ると自動読み込み）。

定型作業はスキル（スラッシュコマンド）で行う：
- `/verify-build` ── ビルド検証（warning / error = 0 維持）。コミット前に必ず。
- `/audit-conventions` ── 規約違反の全走査（`--fix` で修正まで）
- `/adr` ── 意思決定の記録を `docs/adr/` に起こす
- `/release-assets` ── App Store 提出素材（`release/<version>/` のメタデータ .txt とストア画像）の用意・更新
- `/release-version` ── バージョンアップ〜審査提出の運用ランブック（main で反映＋審査PR、production で審査自動提出）
- `/sns-post` ── TikTok / Lemon8 のカルーセル画像投稿（`post/postN/`）を新規に1本作る

---

## 1. このアプリは何か

<アプリの 1〜2 行コンセプトをここに。判断軸・コンセプトの正本は仕様書（あれば DOCUMENT.md）>

新機能を足すときは、まずプロダクトの判断フィルター（あれば）を通す。

---

## 2. ビルド & 実行

- ターゲット：iOS `<deployment_target>` 以上、iPhone のみ（`appstore.config.json` 参照）。
- スキーム・プロジェクト名は `appstore.config.json` の `app.scheme` / `app.xcodeproj`。

ビルド検証コマンド（`<scheme>` / `<xcodeproj>` は config から）：

```bash
xcodebuild -project <xcodeproj> -scheme <scheme> \
  -destination 'generic/platform=iOS Simulator' -configuration Debug build \
  2>&1 > /tmp/log
echo "WARNINGS=$(grep -cE '\.swift:.*warning:' /tmp/log)"
echo "ERRORS=$(grep -cE '\.swift:.*error:' /tmp/log)"
echo "RESULT=$(grep -E 'BUILD (SUCCEEDED|FAILED)' /tmp/log | tail -3)"
```

警告の grep は **必ず** `\.swift:.*warning:` で絞る（無関係なノイズを拾わないため）。
実機でしか検証できない挙動（カメラ・録画等）は、Debug ビルドに環境変数フックや
シードデータを仕込んで CLI から確認できるようにしておくと楽。

---

## 3. Swift / Concurrency

- 推奨：**Swift 5 言語モード + approachable concurrency + MainActor デフォルト隔離**
  （詳細・経緯は `.claude/rules/swift-concurrency.md` と最初の ADR）。
- 対処パターン表（`@preconcurrency import`、`Task.detached` 禁止、
  `nonisolated(unsafe)` の根拠コメント必須など）は `.claude/rules/swift-concurrency.md`。

---

## 4. Xcode プロジェクトの特殊事情（採用する場合）

`PBXFileSystemSynchronizedRootGroup`（Xcode 15+）を使うと、フォルダに `.swift` を
置くだけで自動的にターゲットへ含まれ、`project.pbxproj` の編集が不要になる。

- 新規ファイルは `Edit` / `Write` でディレクトリに作るだけで OK。
- ファイルを削除したら `git status` の `deleted:` を必ず確認する
  （「ファイルだけ消えてビルドが直る」静かな事故が起きやすい）。
- テストターゲットの追加など pbxproj を触る操作は Xcode UI 手作業前提（ADR に残す）。

---

## 5. ディレクトリ構成（このテンプレートが用意するもの）

```
appstore.config.json   ─ アプリ固有値の正本（scripts/Fastfile/post が読む）
CLAUDE.md / SETUP.md    ─ 本ファイルと初回セットアップ手順
.claude/rules/          ─ コーディング・並行性規約（Swift を触ると自動読み込み）
.claude/skills/         ─ /verify-build /audit-conventions /adr /release-assets /sns-post
docs/adr/               ─ 意思決定の記録（template.md / README.md）
scripts/                ─ check_release_metadata / sync_fastlane_metadata / make_store_images
fastlane/Fastfile       ─ App Store Connect へメタデータ反映（deliver）
.github/workflows/      ─ release/** push で ASC へ自動反映
release/<version>/       ─ ストアメタデータ（.txt）・rating.json・img/
material/               ─ 画面スクショ素材（クロマキー #00FF00）・footage/
post/                   ─ SNS カルーセル投稿エンジン

<ここにアプリ本体（hoge/）の主要ファイルの地図を足していく>
```

---

## 6. 触るときの罠と既知ハマりどころ

<アプリ固有の罠をここに蓄積する。コードから読み取れない暗黙の制約だけを集める。
 例：再生ライフサイクル、生成パイプラインの並行性、特定 API のクラッシュ条件など。>

App Store パイプライン側の罠は `release/README.md` の「CI デバッグで踏んだ罠」に集約。

---

## 7. コーディング規約

詳細は `.claude/rules/swift-conventions.md`（自動読み込み）。骨子：
**Tokens / Strings / DisplayDate / AppStorageKeys 経由・`@Observable`・強制アンラップ禁止・
`fatalError` は起動時フォールバックのみ・500 行で分割検討・コメントは「なぜ」だけ**。
規約から外れた箇所を見つけたら `/audit-conventions` で全体を点検する。

---

## 8. 実装の進め方

- **フェーズに分けて都度検証 → 個別コミット**。各コミット末尾に
  `Co-Authored-By: Claude <noreply@anthropic.com>`。
- コミット前に `/verify-build`。ビルドできない環境では diff 精読 + `/audit-conventions` で
  代替し、「ビルド未検証」を明記する。
- アーキテクチャ・データモデル・並行性・依存に関わる決定をしたら `/adr` で記録する。

---

## 9. 着手時チェックリスト

- [ ] `appstore.config.json` を実アプリの値に更新した（新規コピー直後）。
- [ ] 触る領域に関係する ADR（`docs/adr/README.md`）を読んだ。決定を覆すなら新 ADR。
- [ ] 関係ファイルを Read し、既存パターン（`.claude/rules/`）に揃えている。
- [ ] `/verify-build` で warning / error カウントが増えていない（ベースライン = 0）。
- [ ] 触ったコードに `// MARK:` の区分けがある。
- [ ] ファイルを削除したら `git status` の `deleted:` を確認した。
