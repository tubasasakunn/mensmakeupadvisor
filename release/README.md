# release/ ── App Store 提出メタデータ

App Store Connect に入力するテキストとストア画像を、バージョンごとの
ディレクトリで管理する。アプリ固有値（bundle id・連絡先・カテゴリ等）は
リポジトリ直下の `appstore.config.json` を正本とする。

```
release/
└── 1.0/
    ├── app_name.txt          ─ アプリ名（上限 30 文字）
    ├── subtitle.txt          ─ サブタイトル（上限 30 文字）
    ├── promotional_text.txt  ─ プロモーションテキスト（上限 170 文字・審査なしで随時更新可）
    ├── description.txt       ─ 説明（上限 4000 文字）
    ├── keywords.txt          ─ キーワード（上限 100 文字・半角カンマ区切り・空白なし）
    ├── whats_new.txt         ─ このバージョンの新機能（上限 4000 文字）
    ├── primary_category.txt  ─ プライマリカテゴリ（例 PHOTO_AND_VIDEO）
    ├── secondary_category.txt ─ セカンダリカテゴリ（例 LIFESTYLE）
    ├── copyright.txt         ─ 著作権表記（「2026 名義」の形式）
    ├── rating.json           ─ 年齢制限指定の回答（fastlane deliver 形式）
    ├── support_url.txt       ─ サポート URL（必須）
    ├── privacy_url.txt       ─ プライバシーポリシー URL（必須）
    ├── marketing_url.txt     ─ マーケティング URL（任意）
    ├── app_privacy.md        ─ 「アプリのプライバシー」の手動回答シート（CI 対象外）
    └── img/                  ─ ストア用スクリーンショット（横向き）
```

ディレクトリ名は `appstore.config.json` の xcodeproj の `MARKETING_VERSION` と
**完全一致**させる（`grep MARKETING_VERSION <xcodeproj>/project.pbxproj | sort -u`）。
新バージョンは前バージョンをコピーして `whats_new.txt` から書き換えるのが楽。

## 文字数チェック

```bash
python3 scripts/check_release_metadata.py        # 全バージョン
python3 scripts/check_release_metadata.py 1.0    # 特定バージョン
```

App Store Connect と同じく Unicode 1 文字 = 1 カウント（日本語も英数字も等価）。
ファイル末尾の改行 1 つだけはカウント外。keywords の区切りカンマはカウントに含む。
**ファイルを編集したら必ずこのスクリプトを通すこと。** `PASS` 以外はコミットしない。

## ASO 方針（汎用の原則）

Apple はタイトル > サブタイトル > キーワード欄の順に重み付けするため、
**同じ語を複数フィールドで重複させない**のが原則（横断で組み合わせて索引される）。

| フィールド | 担当 |
|---|---|
| アプリ名 | 最重要キーワード＋タグライン |
| サブタイトル | 別軸の検索語 |
| キーワード欄 | 読み・類義語・関連語（重複させない） |

- 競合のブランド名はキーワード欄に**入れない**（App Review ガイドライン 2.3.7 違反リスク）。
- 価格表現（「無料」等）はアプリ名・サブタイトルに入れない（同 2.3.7）。
- 説明文は検索順位に効かないがコンバージョン（DL率）に効く。冒頭にコンセプトと
  差別化を置く。

## ストア画像（img/）

App Store Connect は解像度でシェルフを判定するため、**サイズは 1px もずれると却下**。
各シェルフ最低 3 枚・最大 10 枚。

| 端末シェルフ | サイズ（横向き） | ファイル名 | 元素材 |
|---|---|---|---|
| iPhone 6.9 インチ | **2868×1320px** | `01〜05_*.png` | `material/*.png` |
| iPad 13 インチ | **2752×2064px** | `ipad_01〜05_*.png` | `material/ipad13/*.png` |

iPhone のサイズを上げれば小さい iPhone へ、iPad 13 インチを上げれば他の iPad へ
自動スケールされる。構図・コピーは両者共通（`scripts/make_store_images.py` の
`DEVICES` がレイアウト差分、`scripts/store_slides.json` がスライド構成）。
最新の仕様は App Store Connect の screenshot specifications で確認する。

並び順は ASO の定石どおり「コンセプト → コア操作 → 低コストの記録 → 振り返り →
プライバシー」。最初の 1〜3 枚が検索結果に露出するため、タグラインとコア体験を先頭に。

再生成：

```bash
pip3 install Pillow numpy   # 初回のみ
python3 scripts/make_store_images.py
```

素材は `material/`（動画・画像領域は #00FF00 のクロマキー。詳細は `material/README.md`）。
スクリプトがクロマキー部をダミー映像に差し替え、端末モックアップ・見出し・
アイコングリフを合成する。ダミー映像は `material/footage/` に画像があればそれを採用し、
無ければフラットイラストを自前描画する（生成 AI 用プロンプトは `material/footage/PROMPTS.md`）。
見出しの日本語フォントは Noto Sans JP（OFL）を実行時に取得する。

## 自動反映（CI）

App Store への自動化は 3 ワークフロー・2 fastlane レーンで段階に分かれる。
ブランチへのマージで何が起きるかの運用ランブックは `/release-version` が正本。

| ワークフロー | 起動 | 役割 |
|---|---|---|
| `appstore-metadata.yml` | main の `release/**` 変更 | 文言・スクショを ASC へ反映（`push_metadata`） |
| `release-pr.yml` | main push（`release/**`） | production に無い版を検出し main→production の審査PRを自動作成 |
| `appstore-release.yml` | **production** への push | 最新ビルドを待って審査へ提出（`submit_latest_build`） |

```
release/<MARKETING_VERSION>/ を main へ
  → scripts/sync_fastlane_metadata.py（deliver レイアウトへ変換・名前の対応表の正本）
  → fastlane deliver（push_metadata レーン）でメタデータ反映
  → release-pr.yml が「<version> 審査PR」(main→production) を作成
審査PR を production へマージ
  → fastlane submit_latest_build が Xcode Cloud の処理済み最新ビルドを審査提出
```

- 対象バージョンは pbxproj の `MARKETING_VERSION`。ASC に無ければ新規作成される。
- **バイナリ（ipa）のビルド・アップロードは Xcode Cloud 側**（GitHub の CI ではやらない。
  `ci_scripts/ci_post_clone.sh` がビルド番号を一意化）。
- `push_metadata` は `skip_binary_upload` / `submit_for_review: false`（反映のみ）。
  審査提出は `submit_latest_build` が production マージ時に行う
  （`submit_for_review: true` / `automatic_release: false` で通過後は手動公開）。
- 提出時の固定申告は `submit_latest_build` にハードコード：輸出コンプラ=暗号化なし
  （pbxproj の `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption=NO` と一致）／
  第三者コンテンツなし／IDFA 不使用。アプリ内容が変わったら見直す。
- スクショは `overwrite_screenshots: true` で全置き換え。
- 前段で `check_release_metadata.py` が走り、文字数超過があれば反映前に落ちる。
- カテゴリ・著作権・年齢制限指定（`rating.json`）も毎回反映する。
  **「アプリのプライバシー」だけは API 非対応**のため ASC 画面での手動回答
  （初回のみ・`app_privacy.md`）。
- 審査の連絡先（App Review 情報）も毎回反映する。デフォルトは
  `appstore.config.json` の `contact_email`。任意の Secrets で上書きできる。
  これは「審査情報が未保存のアプリで deliver が No data クラッシュする」
  fastlane の既知バグ（fastlane#21272）の回避を兼ねており、外さないこと。

### GitHub Secrets

| Secret | 必須 | 内容 |
|---|---|---|
| `ASC_KEY_ID` | ✔ | ASC API チームキーのキー ID |
| `ASC_ISSUER_ID` | ✔ | Issuer ID（UUID） |
| `ASC_KEY_CONTENT` | ✔ | `.p8` を base64 化した文字列（`base64 -i AuthKey_XXX.p8`） |
| `ASC_CONTACT_FIRST_NAME` ほか `_LAST_NAME` `_PHONE` `_EMAIL` | 任意 | 審査の連絡先。未設定時は config のメールのみ |

### CI デバッグで踏んだ罠（再発させない）

- **未設定の Secrets は env 上で「空文字列」**になる（nil ではない）。Ruby では
  空文字列も truthy なので `ENV[...] || デフォルト` は効かない。Fastfile の
  `presence` ラムダのように strip + empty? で弾いてから fallback する。
- **fastlane#21272**：審査情報が一度も保存されていないアプリだと deliver が
  `fetch_app_store_review_detail` で `No data (RuntimeError)` 落ちする。対策は
  `app_review_information` を**必ず非空で**渡すこと（Fastfile に実装済み）。
- **ASC の電話番号は E.164 のみ**（`+81…`）。国内表記は Fastfile が +81 へ正規化する。
- **年齢制限（rating.json）は全設問必須**。2025 年新設問（advertising /
  ageAssurance / healthOrWellnessTopics / messagingAndChat / parentalControls /
  userGeneratedContent）が欠けると 409。属性の型は ASC API 公式ドキュメントで確認。
- **「アプリのプライバシー」だけは CI 不可**（Apple ID パスワード前提）。`app_privacy.md`
  の回答シートで ASC 画面から手動回答（初回のみ）。
- 検証目的で workflow に `pull_request` トリガーを一時追加して PR 上で回すのは有効
  （同一リポジトリのブランチなら Secrets が使える）。**緑を確認したら必ず外す**。
- workflow のトリガーは `release/**` のみ。Fastfile や workflow 自体の修正では
  自動起動しないので、Actions 画面の「Run workflow」で手動実行して検証する。
- 失敗ログはエラーの「最初の発生箇所」（`from ...` スタックの最上段）を見る。
  fastlane が末尾に出す GitHub issue 候補は本筋と無関係なことが多い。

### 初回セットアップ（チェックリスト）

リリースまでに 1 回だけ必要な手作業。詳細は `SETUP.md`。

- [ ] App ID（bundle id）登録・アプリレコード作成（ASC）
- [ ] API キー作成 → base64 → GitHub Secrets 登録
- [ ] ワークフロー手動実行で自動反映を確認
- [ ] 「アプリのプライバシー」を ASC 画面で回答（`app_privacy.md`）
- [ ] サポート URL / プライバシー URL のサイトをデプロイ（審査時に開けないと却下）
- [ ] 「価格」と「コンテンツ配信権」を ASC 画面で設定（API 非対応）
- [ ] `production` ブランチを作成（審査提出の自動化に必要。無いと審査PRはスキップ）
- [ ] Settings → Actions →「Allow GitHub Actions to create and approve pull requests」を ON
- [ ] Xcode Cloud のワークフローを作成（archive を ASC へアップロード）
- [ ] 提出は自動：審査PR を production へマージすると最新ビルドを審査へ提出（`/release-version`）

## 更新の流れ

1. 新バージョンのディレクトリを `release/<MARKETING_VERSION>/` として作る。
2. `python3 scripts/check_release_metadata.py` で文字数を確認。
3. 画面が変わっていれば `material/` を撮り直し、`make_store_images.py` で `img/` を再生成。
4. main へマージすると CI が App Store Connect へ自動反映する。ASC 側で確認して提出する。
