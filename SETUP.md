# SETUP ── swift-base を新しいアプリで使う初回手順

このテンプレートを新規アプリのリポジトリにコピーした直後にやること。
上から順に進めれば、コーディング規約・ADR・ビルド検証・ストア提出自動化・
スクショ生成・SNS 投稿までひと通り動く状態になる。

---

## 0. ファイルを置く

`swift-base/` の中身を新規リポジトリ直下にコピーする（アプリ本体の Xcode プロジェクトと
同じ階層に `appstore.config.json` / `scripts/` / `release/` などが並ぶ形）。

```
your-app/
├── YourApp.xcodeproj
├── YourApp/                 ← アプリ本体
├── appstore.config.json     ← swift-base
├── CLAUDE.md / SETUP.md
├── .claude/ docs/ scripts/ fastlane/ .github/ release/ material/ post/
└── Gemfile
```

---

## 1. appstore.config.json を埋める（最重要）

`appstore.config.json` の値を全部実アプリのものに置き換える。これが scripts /
Fastfile / post すべての正本。最低限：

- `app.name` / `app.bundle_id` / `app.scheme` / `app.xcodeproj` / `app.deployment_target`
- `appstore.contact_email` / `appstore.github_repo` / カテゴリ / `marketing_domain`
- `brand.*`（ストア画像・SNS 画像の色とワードマーク。アプリの DesignTokens と揃える）

`CLAUDE.md` の `<...>` プレースホルダも実情に合わせて書き換える。

---

## 2. コーディング規約・集約レイヤを用意する

`.claude/rules/swift-conventions.md` は「集約レイヤ（Tokens / Strings / DisplayDate /
AppStorageKeys / Haptics）を必ず通す」設計を前提にしている。アプリ本体にこれらの
集約ファイルを早めに作っておく（無いと規約が空回りする）。

最初の数件の ADR を起こしておくと後が楽（`/adr`）：
言語モード・データ永続化方針・依存ライブラリの基準 など。

---

## 3. ビルド検証

macOS + Xcode 環境で `/verify-build`。`.swift` 由来の warning / error = 0 を
ベースラインにして維持する。

---

## 4. ストアメタデータ（release/）

1. `release/1.0/` を実アプリ用に編集（`app_name` 等。文字数上限は `release/README.md`）。
   ディレクトリ名は pbxproj の `MARKETING_VERSION` と完全一致させる。
2. `python3 scripts/check_release_metadata.py` が `PASS` になるまで直す。
3. カテゴリ・著作権・年齢制限（`rating.json`）・URL も実値にする。

---

## 5. ストア画像（material/ → release/<version>/img/）

1. アプリの各画面スクショを `material/` に置く（`store_slides.json` が参照する名前で）。
   動画・サムネ領域は **#00FF00 クロマキー**にしておく（差し替え可能になる）。詳細は
   `material/README.md`。
2. スライド構成は `scripts/store_slides.json`、ブランドは `appstore.config.json`。
3. 生成：

   ```bash
   pip3 install Pillow numpy
   python3 scripts/make_store_images.py
   ```

4. `release/<version>/img/` を全枚数 Read で目視確認（観点は `/release-assets`）。

> アイコングリフは角丸スクエア＋頭文字の**プレースホルダ**。実アプリのロゴ／マスコットに
> 差し替えるなら `scripts/make_store_images.py` の `icon_glyph` と `post/_brand.py` の
> `icon_glyph` を書き換える。

---

## 6. App Store Connect 自動反映（CI）の有効化

main へ `release/**` の変更が入ると、`.github/workflows/appstore-metadata.yml` が
文言とスクショを ASC へ自動反映する（バイナリ・審査提出は対象外）。

Apple 側・GitHub 側の 1 回だけの手作業（詳細は `release/README.md` の
「初回セットアップ」と「CI で踏んだ罠」）：

1. **App ID（bundle id）登録** ── Apple Developer ポータルで明示（explicit）登録。
2. **アプリレコード作成** ── App Store Connect で「新規 App」。プライマリ言語は
   `appstore.config.json` の `primary_locale` に合わせる（CI はこのロケールへ書き込む）。
3. **API キー（チームキー）作成** ── ASC の Users and Access → Integrations →
   App Store Connect API → Team Keys。ロールは **App Manager**。
   Issuer ID・Key ID を控え、`.p8` をダウンロード（**1 回きり**）。
4. **base64 化**：`base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy`
5. **GitHub Secrets 登録**（`<github_repo>` の Settings → Secrets → Actions）：

   | Secret | 値 |
   |---|---|
   | `ASC_KEY_ID` | キー ID |
   | `ASC_ISSUER_ID` | Issuer ID（UUID） |
   | `ASC_KEY_CONTENT` | 手順 4 の base64 文字列 |
   | （任意）`ASC_CONTACT_FIRST_NAME` / `_LAST_NAME` / `_PHONE` / `_EMAIL` | 審査連絡先 |

6. **動作確認** ── Actions の「App Store metadata」を手動実行（workflow_dispatch）し、
   緑になることと ASC にメタデータが入ることを確認。以後は `release/**` push で自動反映。
7. **「アプリのプライバシー」** ── API 非対応なので ASC 画面で手動回答
   （`release/<version>/app_privacy.md`）。
8. **サポート / プライバシー URL のサイト**をデプロイ（審査時に開けないと却下）。
9. **「価格」「コンテンツ配信権」** ── API 非対応なので ASC 画面で 1 回設定。
10. **`production` ブランチを作る** ── 審査提出の自動化に必要（`main` から作成）。
    無いと `release-pr.yml` はスキップする。
11. **「PR 作成」権限を ON** ── Settings → Actions → General → Workflow permissions の
    「Allow GitHub Actions to create and approve pull requests」を ON（審査PRの自動作成に必要）。
12. **Xcode Cloud のワークフローを作成** ── 当該バージョンの archive を ASC に
    アップロードする（`ci_scripts/ci_post_clone.sh` がビルド番号を一意化、
    `ci_scripts/ci_pre_xcodebuild.sh` が MediaPipe plist を修正）。

---

## 6.5 審査提出の自動化（メタデータの先の段階）

メタデータ反映（節 6）に加え、**バイナリの審査提出までを自動化**している。
ブランチにマージすると何が起きるかは `/release-version` の運用ランブックが正本。要点：

- **バイナリのビルド／アップロードは Xcode Cloud**（GitHub の CI ではやらない）。
- `release/<version>/` を **main** へマージ → メタデータ反映（`appstore-metadata.yml`）＋
  「<version> 審査PR」(main→production) を自動作成（`release-pr.yml`）。
- その審査PRを **production** へマージ → `appstore-release.yml` が Xcode Cloud の
  処理済み最新ビルドを待って審査へ提出（`fastlane submit_latest_build`）。
- 審査通過後はストアで**手動公開**（`automatic_release: false`）。

提出時の固定申告（`fastlane/Fastfile` の `submit_latest_build`）：
輸出コンプラ=暗号化なし／第三者コンテンツなし／IDFA 不使用。アプリの内容が
変わったら（広告 SDK 追加・第三者素材の同梱など）この 3 値を見直す。

---

## 7. SNS カルーセル投稿（任意）

`post/` の使い方は `post/README.md` と `/sns-post`。アイコングリフは make_store_images と
同じくプレースホルダなので、必要なら差し替える。

```bash
pip3 install Pillow numpy
cd post && python3 build_posts.py && python3 build_index.py
```

---

## 困ったら

- ストア提出パイプラインの罠：`release/README.md`「CI で踏んだ罠」
- 規約・並行性：`.claude/rules/`
- 設計判断の経緯：`docs/adr/`
