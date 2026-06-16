---
name: release-version
description: Tone（mensmakeupadvisor）を新バージョンとして App Store に出すための一連の手順（バージョン番号上げ → メタデータ → main マージで自動反映＆審査PR → Xcode Cloud ビルド → production マージで審査自動提出 → 通過後に手動公開）をまとめた運用ランブック。バージョンアップ時・リリースの仕組みを確認したいときに使う。
argument-hint: "[新しいバージョン番号 例: 1.1.0]"
allowed-tools: Read, Edit, Bash, Grep, Glob
---

# リリース手順（バージョンアップ → 審査提出）

新バージョンを App Store に出すまでの運用ランブック。ストア文言・画像の作成は
`/release-assets`、文字数上限や Secrets の詳細は `release/README.md` が正本。
ここは「どのブランチに何をマージすると何が自動で起きるか」を一望するための入口。
アプリ固有値（bundle id・xcodeproj 名・連絡先）は `appstore.config.json` を読む。

## 0. 全体像（誰が何をやるか）

| 役割 | 担い手 |
|---|---|
| バイナリ（ipa）のビルド・アップロード | **Xcode Cloud**（GitHub の CI ではやらない） |
| メタデータ・スクショの ASC 反映 | `appstore-metadata.yml`（main の `release/**` 変更で起動） |
| 審査PR（main→production）の自動作成 | `release-pr.yml`（main push で、production に無い版を検出） |
| 最新ビルドを選んで審査へ提出 | `appstore-release.yml`（**production への push**で起動）→ `fastlane submit_latest_build` |
| 審査通過後のストア公開 | **手動**（ASC で「リリース」。`automatic_release: false`） |

ブランチの意味：
- **main** … 反映・プレビューと審査PRの起点。
- **production** … 「審査に出した／出す版」。ここに入ると審査提出が走る。
  production の `release/` に無い版＝まだ出していない版、という判定で審査PRが立つ。

```
release/<ver>/ を main へ
  → appstore-metadata.yml: メタデータ反映（プレビュー）
  → release-pr.yml: 「<ver> 審査PR」(main→production) を自動作成/更新
Xcode Cloud: <ver> のビルドをアップロード
「<ver> 審査PR」を production へマージ
  → appstore-release.yml: 処理済み最新ビルドを待って submit_for_review
審査通過 → ASC で手動「リリース」
```

## 1. バージョン番号を上げる

`mensmakeupadvisor.xcodeproj/project.pbxproj` の **`MARKETING_VERSION`**（Debug /
Release の 2 コンフィグ）を上げる。`CURRENT_PROJECT_VERSION`（ビルド番号）も上げて
おくが、**Xcode Cloud では `ci_post_clone.sh` が `CI_BUILD_NUMBER` で上書き**するので
最終的なビルド番号は Xcode Cloud 側で一意になる。

```bash
sed -i 's/MARKETING_VERSION = <old>;/MARKETING_VERSION = <new>;/g; \
        s/CURRENT_PROJECT_VERSION = <n>;/CURRENT_PROJECT_VERSION = <n+1>;/g' \
  mensmakeupadvisor.xcodeproj/project.pbxproj
grep -n "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" mensmakeupadvisor.xcodeproj/project.pbxproj
```

- 2 か所すべて同じ値になることを確認（`sync_fastlane_metadata.py` は
  `MARKETING_VERSION` が一意でないと止まる）。
- 表記は 1.1.0 のような 3 桁でよい。**重要なのは後述の
  `release/<version>/` ディレクトリ名が `MARKETING_VERSION` と完全一致すること**。

## 2. リリース素材（release/<version>/）

`/release-assets` を使う。骨子だけ再掲：

- 前バージョンを丸ごとコピーして始める：`cp -r release/<prev> release/<new>`。
  **`sync_fastlane_metadata.py` は 9 つのテキスト＋スクショが全部揃っていないと
  止まる**ため、差分が無いファイル（説明・キーワード・URL・スクショ等）も必ず同梱する
  （CI は毎回フルセットを ASC に再送する）。
- バージョン固有で必ず書き換えるのは **`whats_new.txt`**（そのバージョンの変更点）。
  画面が変わったときは `material/` を撮り直して `make_store_images.py` で `img/` を再生成。
- 検証：`python3 scripts/check_release_metadata.py <version>` が `PASS`。

## 3. コミット → main へマージ（あなたがマージ）

コミットしてマージすると main で 2 つ自動で動く：

1. `appstore-metadata.yml` … メタデータ・スクショを ASC へ反映（バイナリ・提出はしない）。
2. `release-pr.yml` … production に無い `release/<version>/` を検出し、
   **「<version> 審査PR」(main→production) を作成／更新**。

> どちらも main 上のワークフロー定義で動く。新規ワークフロー自体を入れた回は、
> その変更を含む push から評価される。

## 4. Xcode Cloud でビルドをアップロード

当該 `MARKETING_VERSION` の archive を Xcode Cloud でアップロード。
処理（ASC 側の "PROCESSING"）が終わると TestFlight に出る。

## 5. 「<version> 審査PR」を production へマージ → 審査提出

production への push で `appstore-release.yml` → `fastlane submit_latest_build`：

- ASC のバイナリ処理完了を**最大 45 分ポーリング**で待つ。
- 処理済み最新ビルドを当バージョンに紐付け、メタデータ反映 ＋ `submit_for_review`。
- 提出申告は固定：輸出コンプラ=暗号化なし（pbxproj の
  `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption=NO` と一致）／第三者コンテンツなし
  （端末内完結・BGM や外部素材を同梱しない）／IDFA 不使用（広告・トラッキングなし）。
  この 3 値は `fastlane/Fastfile` の `submit_latest_build` にハードコードしている。
  アプリの内容が変わったら（広告 SDK の追加・第三者素材の同梱など）合わせて見直す。

## 6. 審査通過 → 公開

`automatic_release: false` なので通過後 ASC で手動「リリース」を押す。
**通過即公開にしたい**なら `fastlane/Fastfile` の `submit_latest_build` を
`automatic_release: true` に変える。

## 前提（一度だけ／毎回）

- **GitHub Secrets**（毎回使う）：`ASC_KEY_ID` / `ASC_ISSUER_ID` / `ASC_KEY_CONTENT`
  （.p8 の base64）と連絡先 `ASC_CONTACT_FIRST_NAME` / `_LAST_NAME` / `_PHONE` / `_EMAIL`。
  **審査提出には電話番号が必須**。`ASC_CONTACT_PHONE` は国内表記（070/080/090…）で可
  ── Fastfile が先頭 0 を外して `+81` を付け E.164 へ正規化する。
- **初回のみの ASC 画面設定**（更新版では再要求されない）：価格（無料）・コンテンツ配信権・
  「アプリのプライバシー」（`release/<ver>/app_privacy.md`）。
  詳細は `release/README.md` の「初回セットアップ」と `SETUP.md`。
- production ブランチが存在すること（無いと `release-pr.yml` はスキップ）。
- **GitHub リポジトリ設定**：Settings → Actions → General → Workflow permissions の
  「**Allow GitHub Actions to create and approve pull requests**」を ON にする。
  OFF だと `release-pr.yml` の PR 作成が
  `GitHub Actions is not permitted to create or approve pull requests` で失敗する
  （その場合は審査PRを手動で作る：base=production / head=main / タイトル「<version> 審査PR」）。

## 罠・注意

- **ディレクトリ名 = `MARKETING_VERSION` 完全一致**。ずれると sync が止まる／
  別バージョン扱いになる。
- **`release/` の全ファイルが必須**（差分が無くても同梱）。`whats_new.txt` だけは
  毎回そのバージョンの内容へ。
- ビルド番号は Xcode Cloud（`ci_post_clone.sh`）が上書きするので、pbxproj の
  `CURRENT_PROJECT_VERSION` 手上げはローカル/直アーカイブ時の保険。
- ワークフローは**そのブランチに定義が存在しないと起動しない**
  （main: metadata/release-pr、production: appstore-release）。main→production の
  マージで production 側に appstore-release.yml が乗る。
- MCP の `actions_run_trigger`（workflow_dispatch）は 403。手動起動は GitHub の
  「Run workflow」から。`release-pr.yml` と `appstore-release.yml` は
  workflow_dispatch も持つ。
- fastlane はリモートセッションで実走できない。Fastfile を触ったら
  `ruby -c fastlane/Fastfile` の構文チェックに留め、初回は production への本番マージ前に
  `appstore-release.yml` を workflow_dispatch で 1 度試すのが安全。
- 審査PRは main→production の 1 本のみ（同 head/base）。複数版が溜まると
  最新版のタイトルに更新される。

## 関連ファイル

```
mensmakeupadvisor.xcodeproj/project.pbxproj ─ MARKETING_VERSION / CURRENT_PROJECT_VERSION
                                              INFOPLIST_KEY_ITSAppUsesNonExemptEncryption=NO
appstore.config.json                 ─ bundle id・xcodeproj 名・連絡先（Fastfile/scripts が読む）
ci_scripts/ci_post_clone.sh          ─ Xcode Cloud でビルド番号を CI_BUILD_NUMBER に上書き
ci_scripts/ci_pre_xcodebuild.sh      ─ MediaPipe の xcframework plist 修正（ITMS-90208 回避）
release/<version>/                    ─ メタデータ＋スクショ（/release-assets で用意）
scripts/check_release_metadata.py    ─ 文字数チェック
scripts/sync_fastlane_metadata.py    ─ release/ → fastlane/ 変換（全ファイル必須）
fastlane/Fastfile                    ─ push_metadata / submit_latest_build レーン
.github/workflows/appstore-metadata.yml ─ main の release/** で metadata 反映
.github/workflows/release-pr.yml        ─ main push で main→production 審査PR を自動作成
.github/workflows/appstore-release.yml  ─ production push で最新ビルドを審査提出
release/README.md                    ─ Secrets・初回セットアップ・提出ブロッカーの正本
.claude/skills/release-assets/       ─ メタデータ／ストア画像の作成スキル
```

## チェックリスト

- [ ] `MARKETING_VERSION` を 2 か所すべて上げた（値が一意）。
- [ ] `release/<MARKETING_VERSION>/` を作り、`whats_new.txt` を更新、他は同梱した。
- [ ] `check_release_metadata.py <version>` = PASS。
- [ ] main へマージ（→ metadata 反映＋審査PR 自動作成を確認）。
- [ ] Xcode Cloud で当該バージョンのビルドをアップロード。
- [ ] 審査PR を production へマージ（→ appstore-release.yml の提出成功を確認）。
- [ ] 審査通過後、ASC で「リリース」を押して公開。
