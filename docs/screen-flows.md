# 画面フロー・レイアウト仕様

MensMakeupAdvisor の全画面について、遷移・レイアウト（文言・配置・挙動）を洗い出したドキュメント。

> **2026-05 更新**: UI/UX 改修（Phase A〜C）で多くの英語ラベルが和文化、
> 復帰経路・確認ダイアログが追加された。最新の文言・挙動は本ドキュメント
> 末尾の「UI/UX 改修ログ」を参照。本文中の表は改修前の状態を残している
> 部分があるので、実装は ソース or 改修ログ を正とすること。

ソースは `mensmakeupadvisor/App/RootView.swift` および各 `Features/*` 配下。
画面遷移はすべて `AppState.currentScreen: AppScreen` の切り替えで行われる（`.transition(.opacity)` + `easeInOut 0.35s`）。

```
enum AppScreen { splash, onboarding, home, capture, analyzing, diagnosis, tutorial, studio }
```

---

## 1. 画面遷移マップ

```
                        ┌──────────────┐
                        │   Splash     │
                        │ (.splash)    │
                        └──────┬───────┘
                          2.2s 自動
                               ▼
                        ┌──────────────┐
              ┌─────────│  Onboarding  │
              │         │(.onboarding) │
              │         └──────┬───────┘
              │ SKIP/BEGIN     │ ※BACK は実装なし
              ▼                ▼
        ┌──────────────────────────────┐
        │       Home (.home)           │ ◀───────────┐
        │  ┌──────┬──────┬──────────┐  │             │
        │  │REPORT│CREATE│ ARCHIVE  │  │             │
        │  └──────┴──┬───┴────┬─────┘  │             │
        └─────┬──────┘        │        │             │
              │               │  ARCHIVE: SavedLook   │
              │               │   タップで詳細シート  │
              │               │   →「このルックを編集」│
              ▼               ▼                       │
        ┌──────────────┐                              │
   ┌───▶│ Advice       │                              │
   │BACK│ (.capture)   │                              │
   │    └──────┬───────┘                              │
   │           │ カメラ/サンプル/モック画像           │
   │           ▼                                      │
   │    ┌──────────────┐                              │
   │    │ Analyzing    │                              │
   │    │ (.analyzing) │ (5フェーズ自動進行)          │
   │    └──────┬───────┘                              │
   │           ▼                                      │
   │    ┌──────────────┐                              │
   └────┤ Diagnosis    │                              │
   BACK │ (.diagnosis) │                              │
        └──┬─────────┬─┘                              │
           │BEGIN    │SKIP / OPEN STUDIO              │
           │         │ (skipTutorialOnNextFlow=true時)│
           ▼         │                                │
        ┌──────────────┐                              │
        │ Tutorial     │  ◀─── BACK (step 0 で)       │
        │ (.tutorial)  │       前のステップ ▶ Diagnosis│
        └──────┬───────┘                              │
               │ NEXT 連打 → COMPOSE / SKIP           │
               ▼                                      │
        ┌──────────────┐                              │
        │ Studio       │── REPORT ─▶ Diagnosis        │
        │ (.studio)    │── HOME ───▶ Home ────────────┘
        │              │── ARCHIVE → SavedLook 保存後 Home
        └──────────────┘
```

### Home → Create の特殊ルート
- `HomeCreateTab` の「カメラで撮影する」をタップすると `appState.skipTutorialOnNextFlow = true` がセットされる。
- 以降のフロー: Capture → Analyzing → Diagnosis → **Studio に直行**（Tutorial をスキップ）。
- Studio 終了で Home に戻ったタイミングでフラグはクリアされる。

### Archive → Studio の特殊ルート
- ARCHIVE タブで保存済みルックを開き「このルックを編集」を押すと、`ArchiveViewModel.applyLook` が `composition` を復元し `.studio` に直接遷移する。

---

## 2. Splash 画面

ファイル: `Features/Splash/SplashView.swift`
`accessibilityIdentifier`: `splash_view`

### 役割
ブランドを提示するための静的画面。インタラクションなし。

### レイアウト

| 位置 | 要素 | 文言・スタイル |
|---|---|---|
| 四隅 (offset 20pt) | 十字マーク × 4 | `Color.ivory.opacity(0.25)` / 10×10pt |
| 上部 (top 56pt) | 左 | 「Vol. 01 — Issue No. 001」 monospaced 9pt, inkSecondary |
| 上部 (top 56pt) | 右 | 「A.W. 25/26」 |
| 中央 | キャプション | 「A QUIET STUDY IN」 monospaced 11pt, kerning 2.5, inkSecondary |
| 中央 | タイトル 1 | 「The」 serif 72pt light italic, ivory |
| 中央 | タイトル 2 | 「Better」 serif 80pt bold italic, ivory |
| 中央 | タイトル 3 | 「Self.」 serif 80pt bold italic, **brandPrimary** |
| 中央 | 区切り線 | 高さ 1pt, lineColor |
| 中央 | 和文キャッチ | 「紳士の身嗜み、再考。」 13pt regular, inkSecondary, kerning 1.5 |
| 下部 (bottom 48pt) | 1 行目 | 「EST. MMXXV」 monospaced 9pt, kerning 2.0 |
| 下部 | 2 行目 | 「Hommes · Atelier」 monospaced 10pt, kerning 1.5 |

水平 padding 28pt、左寄せ。

### 挙動・遷移
- `.task` で `Task.sleep(for: .seconds(2.2))` → `appState.navigate(to: .onboarding)`。
- タップ・スワイプ反応なし。戻る手段なし。

---

## 3. Onboarding 画面

ファイル: `Features/Onboarding/OnboardingView.swift`
ページ定義: `Models/OnboardingPage+Ch01_04.swift`, `OnboardingPage+Ch05_08.swift`
`accessibilityIdentifier`: `onboarding_view`

### 共通枠

| ブロック | 内容 | 主な ID |
|---|---|---|
| Header (top 12, hp 28) | 左：ページタグ（例「CHAPTER 01」「FACT NO. 01」）<br>右：「SKIP →」ボタン（枠線 inkSecondary 0.4） | `onboarding_page_tag`<br>`onboarding_skip_button` |
| Progress (高さ 1.5pt) | 背景 lineColor、進捗 ivory 0.7、幅 = (currentPage+1)/53 ・ easeInOut 0.25 | `onboarding_progress_bar` |
| Folio | 右寄せ「p. 001 of 053」 monospaced 9pt, inkSecondary 0.6 | `onboarding_folio_label` |
| TabView | `.page(indexDisplayMode: .never)` でスワイプ／コンテンツは ScrollView | `onboarding_page_content` |
| Bottom (bottom 32) | 最終ページのみ「BEGIN →」ボタン（glassEffect capsule） | `onboarding_continue_button` |

- スワイプで前後ページ遷移。BEGIN/SKIP はどちらも `appState.navigate(to: .capture)`。
- 全ページ共通で戻り不可（外への出口は SKIP/BEGIN のみ）。

### ページ一覧（全 53 ページ）

13 種類のページタイプを `OnboardPageContentView` で描画。

| # | タイプ | タグ | 主要文言（タイトル） |
|---|---|---|---|
| **Chapter 01 — 共感** ||||
| 0 | cover | CHAPTER 01 | 「鏡を見るたび、何かが惜しい。」 |
| 1 | stat | FACT NO. 01 | 55% — 見た目が、第一印象を決める比率 |
| 2 | stat | FACT NO. 02 | 0.1秒 — 相手があなたを値踏みするまでの時間 |
| 3 | stat | FACT NO. 03 | 71.9% — 20代男性のうち、美容に興味がある人の割合 |
| 4 | stat | FACT NO. 04 | 3,000回 — 鏡を見る回数 |
| 5 | stat | FACT NO. 05 | 7年 — 清潔感のある外見で得する時間 |
| 6 | compare | A QUICK DEMO | 「同じ顔で、印象は変えられる。」（Before/After スライダー） |
| **Chapter 02 — なぜやるか** ||||
| 7 | cover | CHAPTER 02 | 「これは「身嗜み」で、「化粧」じゃない。」 |
| 8 | concept | WHY 01 | The Halo. ハロー効果 |
| 9 | concept | WHY 02 | The Mirror. 鏡の効果 |
| 10 | concept | WHY 03 | The Wage Gap. 外見プレミアム |
| 11 | concept | WHY 04 | The Confidence Loop. 自信の連鎖 |
| 12 | stat | FACT NO. 06 | 38% — 交際相手の外見を「重視する」と答えた男性の割合 |
| **Chapter 03 — 理論** ||||
| 13 | cover | CHAPTER 03 | 「メイクには、ちゃんと理屈がある。」 |
| 14 | principle | BEFORE WE START | 「先に、二つだけ確認。」（スキンケア／体型） |
| 15 | thesis | THE ONE-LINE THEORY | 「メイクとは、…バランス／光と影…」 |
| 16 | principle | CORE · 1 | 「顔には、「整って見える比率」がある。」 |
| 17 | principle | CORE · 2 | 「目指すのは、あなたの最良版。」 |
| 18 | principle | CORE · 3 | 「使う道具は、光と影だけ。」 |
| 19 | principle | CORE · 4 | 「あなたの「顔タイプ」を知る」（卵型／面長／丸顔／ベース型） |
| **Chapter 04 — 光と影** ||||
| 20 | cover | CHAPTER 04 | 「結局、光と影。」 |
| 21 | duo | THE TWO TOOLS | Light（明るくする = 前に出す）／ Shadow（暗くする = 奥に） |
| 22 | example | HOW TO USE IT | Q「目と目が近すぎる」「離れすぎる」 |
| 23 | example | MORE EXAMPLES | Q「頬が大きい」「鼻が低い」「おでこが広い」 |
| 24 | principle | BONUS | 「色も、結局は光と影の仲間。」 |
| **Chapter 05 — 男性特有** ||||
| 25 | cover | CHAPTER 05 | 「男のメイクは、「気づかれない」が前提。」 |
| 26 | principle | RULE 01 | 「「気づかれない範囲」をデフォルトにする。」 |
| 27 | principle | RULE 02 | 「一度に、やりすぎない。」 |
| 28 | principle | RULE 03 | 「週3回から始める」 |
| 29 | principle | RULE 04 | 「道具は最小限から」 |
| 30 | goal | THE TARGET | 「目指すのは、「調子のいい日の自分」。」 |
| **Chapter 06 — 5 ステップ** ||||
| 31 | cover | CHAPTER 06 | 「やることは、五つだけ。」 |
| 32 | feature | STEP 01 | I · Base · ベース 「まず、ノイズを消す。」 |
| 33 | howto | STEP 01 · DETAIL | 「BBクリームの選び方」+ Base アニメーション |
| 34 | feature | STEP 02 | II · Highlight · ハイライト 「骨を、少しだけ立たせる。」 |
| 35 | howto | STEP 02 · DETAIL | 「ハイライトの当て方」+ Highlight アニメーション |
| 36 | feature | STEP 03 | III · Shadow · シェーディング 「輪郭を、そっと削る。」 |
| 37 | howto | STEP 03 · DETAIL | 「シェーディングの当て方」+ Shadow アニメーション |
| 38 | feature | STEP 04 | IV · Eyes · アイ 「目だけは、ちゃんと作る。」 |
| 39 | howto | STEP 04 · DETAIL | 「目元の仕上げ方」+ Eyes アニメーション |
| 40 | feature | STEP 05 | V · Brows · 眉 「眉で、顔つきが決まる。」 |
| 41 | howto | STEP 05 · DETAIL | 「眉の整え方」+ Brows アニメーション |
| **Chapter 07 — よくある失敗** ||||
| 42 | cover | CHAPTER 07 | 「よくある、ちょうどいい失敗。」 |
| 43 | principle | MISTAKE 01 | 「「全部やる」で逆効果」 |
| 44 | principle | MISTAKE 02 | 「量が多すぎる」 |
| 45 | principle | MISTAKE 03 | 「「バレたくない」が強すぎて効果ゼロ」 |
| **Chapter 08 — 最後の一歩** ||||
| 46 | cover | CHAPTER 08 | 「ここから先は、読む話じゃない。」 |
| 47 | cover | SIX MONTHS LATER | 「半年後の、ある月曜の朝。」 |
| 48 | stat | OR — THE OTHER MORNING | 1,095 — 何もしなければ素通りする朝の数 |
| 49 | list | HOW TO TAKE IT BACK | 「その朝を、取り戻す手順。」(撮る／診断を読む／顔の上で試す) |
| 50 | list | WHAT WE PROMISE | 「取り戻す道具として、三つを守ります。」 |
| 51 | stat | THE COUNTDOWN | 21日 — 「当たり前」に変わるまでの日数 |
| 52 | cta | LET'S BEGIN | 「あの朝を、取り戻す。」 |

### Howto アニメーション
Base / Highlight / Shadow / Eyes / Brows それぞれ `Howto*Animation.swift` でキーフレーム自動再生（aspect 1:1, 最大幅 260pt）。

---

## 4. Home 画面

ファイル: `Features/Home/HomeView.swift`
`accessibilityIdentifier`: `home_view`

### 共通構造
- `TabView`（独自実装）で 3 タブを横並び。デフォルトは中央の **CREATE**。
- 背景: `Color.appBackground`、タブラベル: `Color.ivory`。
- Home に来た時点で `skipTutorialOnNextFlow = false` をリセット（安全のため）。

| タブ | ID | アイコン | ラベル |
|---|---|---|---|
| REPORT | `home_tab_report` | `doc.text.magnifyingglass` | REPORT |
| CREATE（既定） | `home_tab_create` | `sparkles` | CREATE |
| ARCHIVE | `home_tab_archive` | `square.grid.2x2` | ARCHIVE |

---

### 4-1. CREATE タブ

ファイル: `Features/Home/Components/HomeCreateTab.swift` / ID: `home_create_tab`

| 順 | 要素 | 文言 |
|---|---|---|
| 1 | ヘッダー | 「CREATE · NEW LOOK」（monospaced 10pt, kerning 2.5） |
| 2 | タイトル | 「compose.」serif 38pt italic ＋「新しいルック.」serif 32pt bold italic |
| 3 | 区切り線 | 1pt lineColor |
| 4 | ヒーロー | 「01 · 撮影」/「自分の顔を撮る。\n顔の比率から、\nメイクを設計する。」/「· 撮影 → 7 指標で評価 → スタジオで調整 ·」 |
| 5 | プライマリボタン | **「カメラで撮影する →」** 背景 ivory／テキスト appBackground（ID: `home_create_camera_button`） |
| 6 | フッターヒント | 「前回: [顔形] · [評価]」または「はじめての撮影」 |

挙動:
- カメラボタン → `appState.skipTutorialOnNextFlow = true` → `.capture` へ遷移。以降 Tutorial をスキップして Studio に直行。

---

### 4-2. REPORT タブ

ファイル: `HomeReportTab.swift` / ID: `home_report_tab`

| 順 | 要素 | 文言・備考 |
|---|---|---|
| 1 | ヘッダー | 「YOUR FACE · REPORT」 |
| 2 | タイトル | 「your face.」serif 38pt light italic ＋「評価レポート.」serif 32pt bold italic |
| 3 | 区切り線 | 1pt lineColor |
| 4a | **結果あり** | サマリカード（顔形ラベル / グレード S/A/B/C/D / 総ポイント / 説明 / 百分位）＋ 7 CRITERIA リスト（各項目に名称・グレード・点） |
| 4b | **結果なし** | 「⊕」/「まだ、評価結果はありません」/「最初の顔評価から始めましょう。」 |
| 5 | アクション | 結果あり: 「詳細レポートを開く →」(outline / ID: `home_report_open_button`) ＋ 「再評価する」(fill / `home_report_reeval_button`) <br> 結果なし: 「評価を始める →」(`home_report_start_button`) |

挙動:
- 詳細 → `.diagnosis`（skipTutorial フラグはクリア）
- 再評価／開始 → `.capture`

---

### 4-3. ARCHIVE タブ

ファイル: `HomeArchiveTab.swift` / ID: `home_archive_tab`
データ源: `@Query(sort: \SavedLook.createdAt, order: .reverse)`

| 順 | 要素 | 文言・備考 |
|---|---|---|
| 1 | ヘッダー | 「ARCHIVE · YOUR LOOKS」 |
| 2 | タイトル | 「your archive.」 ＋ 「[count] looks saved」 |
| 3 | 区切り線 | — |
| 4a | **空** | 「♡」/「まだ、保存はありません」/「CREATE タブからルックを作って\nスタジオで保存してください。」 ID: `home_archive_empty` |
| 4b | **有り** | LazyVGrid 3 列 × 可変行、各セルは `SavedLookMeshThumbnail`（1:1）。totalScore > 0 なら右下にグレード（serif 11pt） ID: `home_archive_card_{look.id}` |

- セルタップ → SavedLook 詳細シート（modal）。

---

### 4-4. SavedLook 詳細シート

ファイル: `SavedLookDetailSheet.swift` / ID: `home_archive_detail_sheet`

| 順 | 内容 |
|---|---|
| 1 | ヘッダー: 左=作成日時 `YYYY-MM-DD HH:MM`、右=`[totalScore]pt`（>0 のとき） |
| 2 | サムネイル: `SavedLookMeshThumbnail`（maxWidth 320, lineColor 枠） |
| 3 | 適用ゾーン: HIGHLIGHT / SHADOW / EYE / BROW（areaSet を「 · 」結合、空は「—」） |
| 4 | INTENSITY: BASE / HIGHLIGHT / SHADOW / EYE の各値（serif 14pt） |
| 5 | アクション: 「削除」(`home_archive_detail_delete`) ／「このルックを編集 →」(`home_archive_detail_apply`) |

挙動:
- 削除 → `ArchiveViewModel.deleteLook` → SwiftData から物理削除。
- 編集 → `applyLook`: SavedLook から `MakeupComposition` を構築 → `appState.composition` 反映 → `skipTutorialOnNextFlow = true` → `.studio` へ遷移。

---

## 5. Advice (Capture) 画面

ファイル: `Features/Advice/AdviceView.swift` / `AdviceViewModel.swift`
ID: `advice_capture_view`

### レイアウト（上から）

| 順 | 要素 | 文言・スタイル |
|---|---|---|
| 1 | ナビ左 | 「← BACK」(monospaced 11pt, kerning 1.5, inkSecondary)（ID: `advice_back_button`） → `.onboarding` |
| 2 | チャプター | 「CHAPTER 07 · SCAN」 monospaced 10pt kerning 2.5 |
| 3 | 小見出し | 「step one.」 serif 42pt light italic, brandPrimary |
| 4 | タイトル | 「まず、あなたの顔を\nちゃんと、知る。」 serif 28pt bold italic, ivory |
| 5 | 区切り線 | 1pt lineColor |
| 6 | 説明 | 「顔の比率・骨格・左右対称性を\n7つの指標で分析。あなただけの\nメイクアドバイスを導き出す。」 13pt regular, inkSecondary |
| 7 | ビューファインダー | 280pt 高さ、楕円破線、4 隅マーク、ドット「LIVE」、「顔を枠内に合わせてください」 |
| 8a | **本番**: プライマリボタン | 「カメラで撮影する →」 + `camera.fill` 14pt（ID: `advice_camera_button`） |
| 8b | **モック**: モックピッカー | 「画像1」「画像2」「画像3」(`advice_mock_image_0/1/2`、親 `advice_mock_image_picker`)、オレンジ枠 |
| 9 | セカンダリボタン | 「サンプル画像で試す」 outline（ID: `advice_sample_button`） |
| 10 | プライバシー | 「— 端末内処理 · アップロードなし · 痕跡なし —」 monospaced 10pt kerning 1.0, inkTertiary |

### 挙動・遷移
- カメラ → `fullScreenCover` で `CameraCaptureView`（UIImagePickerController, シミュレータでは `.photoLibrary` フォールバック）。撮影後 `uprightOriented()` で向き正規化 → `appState.capturedImage` → `.analyzing`。
- サンプル → `onboarding_face_before` を読み込み（無ければプログラム生成） → `.analyzing`。
- モック画像 → 上と同じパス。
- BACK → `.onboarding`。

ViewModel 状態:
- `showCamera: Bool`、`errorMessage: String?`

---

## 6. Analyzing 画面

ファイル: `Features/Advice/AnalyzingView.swift`
ID: `analyzing_view`（独自 ViewModel なし、AppState＋AnalysisService を直接参照）

### レイアウト

| 位置 | 要素 | 文言・スタイル |
|---|---|---|
| 上 (top 56, hp 24) | バッジ | 「IN PROGRESS」 monospaced 9pt kerning 2、背景 ivory 0.85、テキスト appBackground |
| 上右 | エラー文 | `errorMessage` がある場合のみ |
| 中央 | タイトル | 「analysing…」 serif 52pt light italic, ivory |
| 中央 | サブ | 「your facial geometry」 monospaced 12pt kerning 1.5 |
| 中央 | スキャン領域 | 撮影画像をグレースケール化（saturation 0, brightness -0.1, contrast 0.9）＋ 8×10 メッシュグリッド＋スキャンライン（gradient 高さ 2pt, 2 秒ループ） |
| 下 (bottom 56, hp 24) | フェーズ | 現在: ivory medium、それ以外: 「·」inkTertiary（ID: `analyzing_phase_label`） |
| 下 | プログレスバー | 高さ 2pt、背景 lineColor、進行 brandPrimary、easeInOut 0.4（ID: `analyzing_progress_bar`） |

### 分析フェーズ
```
PREPARING (0.0)
  → 400ms → progress 0.20
LOADING IMAGE
  → 300ms → progress 0.40
DETECTING FACE
  → AnalysisService.analyze(image, sharedEngine)
    ├─ MakeupEngineService.prepare (MediaPipe FaceLandmarker + crop)
    └─ analyze (FaceScoringEngine, 7 指標)
  → progress 0.70
MEASURING PROPORTIONS
  → 600ms → progress 1.0
COMPLETE
  → 400ms → appState.capturedImage = cropped, appState.analysisResult = result
  → navigate(.diagnosis)
```

### エラー
- `capturedImage` nil → `"画像が取得できませんでした"` を表示、停止。
- MediaPipe 検出失敗 → `AnalysisService` がフォールバック（固定スコア `[70,68,65,72,67,63,71]`）を返し、そのまま Diagnosis へ。
- その他例外 → `"解析に失敗しました"` を表示、画面に留まる（戻る手段なし）。

---

## 7. Diagnosis 画面

ファイル: `Features/Advice/DiagnosisView.swift`
ID: `diagnosis_view`（`.accessibilityElement(children: .contain)`）

### ナビ
- 左: 「← BACK」(`diagnosis_back_button`) → `.capture`
- 右: 「DIAGNOSIS · REPORT」

### ヘッダーセクション（ScrollView 内）
- 「CHAPTER 07 · RESULT」
- 「step two.」 serif 38pt light italic, brandPrimary
- **「診断結果.」** serif 44pt bold italic, ivory
- キャプション「— a study of seven proportions —」
- 1pt 区切り線

### Hero セクション (`DiagnosisHeroSection`)
- 左: `ScoreRingView`（160pt、ivory ストローク、interpolatingSpring 1.4s）中央に「XX OF 100」 — ID: `diagnosis_score_ring`
- 右下バッジ: グレード文字（S/A/B/C/D）。初期 opacity 0 / scale 0.4 → 1.5 秒後 spring 表示。
- 右テキスト:
  - 「FACE SHAPE」ラベル
  - 顔型: 「卵型／丸顔／面長／逆三角／ベース型」 serif 24pt bold italic
  - 「[グレード] · [説明]」（exceptional / excellent / good balance / standard / needs care）
  - 「上位 約[3/8/15/22/...]%」
  - 顔型 note（regular 11pt 5 行）

### Share プロンプト (`DiagnosisSharePrompt`) — ID: `diagnosis_share_button`
- 左: 顔ミニカード（68×88）
- 中央: 「SHARE RESULT」/「メイク前の素顔スコア — あなたは何点？」
- 右: `arrow.up.forward` または `ProgressView`（生成中）
- タップで `DiagnosisShareCardView` を画像化（ShareHelper）→ iOS share sheet。

### フェイスメッシュプレート — ID: `diagnosis_face_mesh_plate`
- 撮影画像 opacity 0.55、478 ランドマークの点＋edge を描画（ivory 0.65 / 0.28）。
- ランドマーク未取得時はプレースホルダグリッド。
- 左下キャプション「FIG. 01」「FACE MESH · 478 PTS」。

### 比率プレート — ID: `diagnosis_proportion_plate`
- 撮影画像 opacity 0.65。
- 縦三分割線（brandPrimary 0.85）にラベル「① 額」「② 中」「③ 顎」。
- 横五分割線（sulphur 0.85）。
- 計測ライン（ivory 0.95）: 目幅、口幅、鼻幅。
- 左下「FIG. 02」「PROPORTIONS · 3RDS / 5THS」。

### スコアリストセクション — ID: `diagnosis_score_list`
- 「STRONGEST」（最高指標）と「NEEDS CARE」（最低指標）の対比カード。
- 「7 CRITERIA — DETAILED REPORT」
- 7 指標カード（`ScoreCardView`、ID: `diagnosis_score_card_<指標名>`）
  - n°01〜07、指標名、グレード、点数、プログレスバー（gradeColor）、アドバイス文（FaceScore.pickAdvice によりスコアと metrics に応じて分岐）
  - タップで展開: `ScoreAnnotationView` が撮影画像上に評価対象部位を線描画
    - 骨格バランス → FIG · 顔幅・顔高・頬骨ライン
    - 三分割比率 → FIG · 額／中顔面／下顔面
    - 五分割比率 → FIG · こめかみ〜目尻〜目頭
    - 目の比率 → FIG · 目の縦×横
    - 鼻のバランス → FIG · 鼻幅と目間の対比
    - 口の比率 → FIG · 口幅と上下唇の厚み
    - 左右対称性 → FIG · 中央線とペア点

### 下部アクション

| ボタン | 文言 | 条件 | 遷移 | ID |
|---|---|---|---|---|
| メイン | 「BEGIN COMPOSITION」 | `skipTutorialOnNextFlow == false` | `.tutorial` | `diagnosis_begin_button` |
| メイン | 「OPEN STUDIO」 | `skipTutorialOnNextFlow == true` | フラグをクリア後 `.studio` | 同上 |
| サブ | 「Skip to fine tuning」 | 常時 | `.studio` | `diagnosis_skip_button` |

### スコアリングルール
- 総合スコア = 7 指標スコアの平均。
- グレード: S(85+) / A(75+) / B(65+) / C(55+) / D(55-)。
- 色: S/A=ivory, B=sulphur, C/D=brandPrimary。
- 百分位は段階表（90+→3%、85+→8%、80+→15%、75+→22%、…）。

---

## 8. Tutorial 画面

ファイル: `Features/Tutorial/TutorialView.swift` / `TutorialViewModel.swift`
ID: `tutorial_view`

### 上から下のレイアウト

| 順 | 要素 | 内容 | ID |
|---|---|---|---|
| 1 | ヘッダー (top 8, hp 28) | 左「← BACK」／中央「ACT [tag] OF [count]」（例 "ACT I OF 5"）／右「SKIP →」 | `tutorial_back_button`, `tutorial_skip_button` |
| 2 | ステップドット (top/bottom 12) | 現在 7×7、その他 4×4。色はレイヤー: base=ivory0.5, highlight=ivory, shadow=brandPrimary, eye=sulphur, eyebrow=茶 | — |
| 3 | 顔プレート (hp 28) | 撮影画像のアスペクト保持。`renderedImage` 優先、左上にステップタグ。プレースホルダ時「ACT [tag] · [部位名]」 | — |
| 4 | ステップ情報 (top 16, hp 28) | 「ACT [tag] · [レイヤー]」「[部位名].」serif 24pt bold italic／ワンライナー serif 13pt semibold italic／詳細本文 12pt 6 行／コントロール（スライダー or 眉ピッカー） | `tutorial_step_info` |
| 5 | ナビ (bottom 32, hp 28) | 右寄せ「NEXT ACT →」 or 最後のみ「COMPOSE →」 monospaced 12pt semibold | `tutorial_next_button` |

### コントロール
- **強度スライダー** (`TutorialIntensitySlider`、非眉ステップ): 「INTENSITY」ラベル＋値（serif 36pt light italic）。0–100、ハンドル左右ドラッグ、目盛り「OFF · 50 · MAX」。デフォルト: base 40 / highlight 50 / shadow 35 / eye 40。
  - ID: `tutorial_intensity_slider_{layer}` (base/highlight/shadow/eye)
- **眉ピッカー** (`TutorialEyebrowPicker`、眉ステップのみ): 2×3 グリッド「OFF / NATURAL / STRAIGHT / ARCH / PARALLEL / CORNER」、顔型に応じた推奨に「★ おすすめ」。
  - ID: `tutorial_brow_type_picker`、各ボタン `tutorial_brow_type_{type}`

### 挙動
- 入場で `resetToFirstStep()` → 強度初期化、`tutorialStep = 0`、`renderedImage = nil`。
- スワイプ左/右で前後ステップ（最小距離 24pt、速度差 56pt）。step 0 で右スワイプ → Diagnosis に戻る。
- ステップ進行で composition を「step 0 から現在まで」順に再合成。renderKey = `{step}|{browType}|{intensities,カンマ}` 単位で 80ms debounce 後にレンダリング要求。
- ステップ列は顔型依存（`TutorialStep.sequence(for:)`）:

| 顔型 | base | highlight | shadow | eye | eyebrow | 計 |
|---|---|---|---|---|---|---|
| tamago（卵型） | 1 | 5 | 1 | 5 | 1 | 13 |
| marugao（丸顔） | 1 | 3 | 1 | 5 | 1 | 11 |
| omonaga（面長） | 1 | 2 | 2 | 5 | 1 | 11 |
| gyaku（逆三角） | 1 | 5 | 1 | 5 | 1 | 13 |
| base（ベース型） | 1 | 5 | 2 | 5 | 1 | 14 |

各ステップの本文は `TutorialStepExplanations` テーブルで顔型 × 部位の組合せにより 1:1 で出し分け。

### 遷移
- NEXT 最終ステップ／SKIP / COMPOSE → `finishToStudio()`: 眉未選択なら推奨タイプを埋め、composition を `appState.composition` に書き、`tutorialDone = true` → `.studio`。
- BACK at step 0 → `.diagnosis`。

---

## 9. Studio 画面

ファイル: `Features/Studio/StudioView.swift` / `StudioViewModel.swift`
ID: `studio_view`

### 上から下のレイアウト

| 順 | 要素 | 内容 | ID |
|---|---|---|---|
| 1 | ヘッダー (top 8, hp 28) | 左「← REPORT」／中央「ATELIER · STUDIO」／右「HOME →」 | `studio_back_button`, `studio_header_home_button` |
| 2 | 画像プレート (hp 28, top 12) | COMPARE: Before/After スライダー（中央に白線、左下「FIG. A — BEFORE」、右下「FIG. B — AFTER」、ドラッグ範囲 0.05–0.95）／FINE TUNE: After のみ。右上に「SCORE [n]」チップ。レンダリング中は「RENDERING…」 | — |
| 3 | モードセグメント (top 16, hp 28) | 2 列「COMPARE / FINE TUNE」、選択は ivory／appBackground 反転、easeInOut 0.2 | `studio_compare_button`, `studio_finetune_button` |
| 4 | コントロールパネル | COMPARE: PresetPanelView ／ FINE TUNE: ScrollView(FineTunePanelView) | — |
| 5 | ボトムバー (bottom 32, hp 28) | 左「♥ ARCHIVE THIS LOOK」（expand, lineStrong 枠）／右「↑」 52pt（生成中は ProgressView） | `studio_save_button`, `studio_share_button` |

### PresetPanelView（COMPARE）
LazyVGrid 2 列、見出し「EDITOR'S PRESETS」、各カード「n°.0X」/ プリセット名 / タグ。

| ID | ラベル | タグ | base | highlight | shadow | eyeshadow | tearbag | eyeliner |
|---|---|---|---|---|---|---|---|---|
| natural | ナチュラル | バレない | 0.22 | 0.18 | 0.14 | 0.12 | 0.12 | 0.12 |
| kireime | キレイめ | オフィス | 0.30 | 0.25 | 0.22 | 0.20 | 0.18 | 0.20 |
| mode | モード | クール | 0.28 | 0.32 | 0.35 | 0.32 | 0.22 | 0.35 |
| k-style | Kスタイル | SNS映え | 0.35 | 0.40 | 0.28 | 0.42 | 0.35 | 0.42 |

ID: `studio_preset_{preset.id}` (`studio_preset_natural`, `studio_preset_kireime`, `studio_preset_mode`, `studio_preset_k-style`)

タップで `composition.intensities` 一括反映（animation 0.3s）、`appState.activePresetID` 更新、非同期レンダリング。

### FineTunePanelView（FINE TUNE）
ScrollView 内。6 種の `StudioSlider`（横線、ハンドル ivory 6×14、0–100）と「BROW TYPE」グリッド。

| 強度スライダー ID | ラベル |
|---|---|
| `studio_intensity_base` | BASE |
| `studio_intensity_highlight` | HIGHLIGHT |
| `studio_intensity_shadow` | SHADOW |
| `studio_intensity_eyeshadow` | EYESHADOW |
| `studio_intensity_tearbag` | TEAR BAG |
| `studio_intensity_eyeliner` | EYELINER |

- 値表示: serif 20pt light italic、目盛り「OFF · 50 · MAX」。
- 眉グリッド（adaptive min 88）: OFF / NATURAL / STRAIGHT / ARCH / PARALLEL / CORNER。 ID: `studio_brow_type_{value}`。Studio では推奨表示なし。

### Save / Share

| ボタン | 動作 |
|---|---|
| **ARCHIVE THIS LOOK** | `StudioViewModel.saveLook` で `SavedLook` を作成 → `modelContext.insert / save` → Toast「✓ LOOK ARCHIVED」(opacity フェード、1.4 秒後消去、ID: `studio_saved_notification`) → Home に遷移 |
| **↑（Share）** | 非同期で `DiagnosisShareCardView` をレンダリング → `ShareHelper.present()` で iOS Share Sheet。中は ProgressView 表示 |

### 遷移
- REPORT → `.diagnosis`、HOME → `.home`、ARCHIVE → 保存 → `.home`。
- パネル内操作は遷移なし、composition 更新→ 80ms debounce → `MakeupEngineService.render` → `renderedImage` 反映。

### MakeupComposition モデル要点
- `units: [MakeupKind: MakeupUnit]`。Kind: base / highlight / shadow / eyeshadow / tearbag / eyeliner / eyebrow（renderOrder 0〜6）。
- mesh-based (highlight/shadow/eyeshadow/tearbag): meshColors の alpha を一律更新で強度反映。
- tint-based (base/eyeliner/eyebrow): tint.a 更新。
- 眉は `browType` を持ち、非 nil で tint 可視化。

---

## 10. accessibilityIdentifier 全一覧

| 画面 | ID | 要素 |
|---|---|---|
| Splash | `splash_view` | 画面全体 |
| Onboarding | `onboarding_view` / `_page_tag` / `_skip_button` / `_progress_bar` / `_folio_label` / `_page_content` / `_continue_button` / `_compare_slider` | 各 UI 要素 |
| Home | `home_view` / `home_tab_report` / `home_tab_create` / `home_tab_archive` | タブ枠 |
| Home Create | `home_create_tab` / `home_create_camera_button` | — |
| Home Report | `home_report_tab` / `home_report_open_button` / `home_report_reeval_button` / `home_report_start_button` | — |
| Home Archive | `home_archive_tab` / `home_archive_empty` / `home_archive_card_{look.id}` | グリッド |
| Detail Sheet | `home_archive_detail_sheet` / `home_archive_detail_delete` / `home_archive_detail_apply` | — |
| Advice | `advice_capture_view` / `advice_back_button` / `advice_camera_button` / `advice_sample_button` / `advice_mock_image_picker` / `advice_mock_image_0..2` | — |
| Analyzing | `analyzing_view` / `analyzing_phase_label` / `analyzing_progress_bar` | — |
| Diagnosis | `diagnosis_view` / `_back_button` / `_score_ring` / `_share_button` / `_face_mesh_plate` / `_proportion_plate` / `_score_list` / `_score_card_<指標>` / `_begin_button` / `_skip_button` | — |
| Tutorial | `tutorial_view` / `_back_button` / `_skip_button` / `_next_button` / `_step_info` / `_intensity_slider_{layer}` / `_brow_type_picker` / `_brow_type_{type}` | — |
| Studio | `studio_view` / `_back_button` / `_header_home_button` / `_compare_button` / `_finetune_button` / `_preset_{id}` / `_intensity_{kind}` / `_brow_type_{value}` / `_save_button` / `_share_button` / `_saved_notification` | — |

---

## 11. Maestro フロー対応表

| ファイル | 主な検証範囲 |
|---|---|
| `splash_flow.yaml` | Splash 自動遷移 → Onboarding 到達 |
| `onboarding_flow.yaml` | Onboarding 表示、Continue / Back / Skip 動作、Advice 到達 |
| `advice_flow.yaml` | モック画像選択 → Analyzing → Diagnosis 各 ID → BEGIN → Tutorial 到達 |
| `diagnosis_visual_flow.yaml` | Diagnosis のメッシュ／比率プレートのスクリーンショット採取 |
| `tutorial_flow.yaml` | スワイプ前後 + NEXT 連打で Studio 到達 |
| `studio_flow.yaml` | プリセット選択 → 保存 → 通知表示 |
| `finetune_base_check_flow.yaml` | FINE TUNE、Base スライダー最大、レンダリング前後のスクショ |
| `makeup_render_smoke_flow.yaml` | プリセット適用前後のレンダリングスモーク |
| `archive_flow.yaml` | 保存 → Archive 表示 |
| `share_flow.yaml` | Diagnosis / Studio のシェア機能 |
| `mediapipe_smoke_flow.yaml` | MediaPipe 顔検出スモーク |

---

## 12. グローバル状態 (AppState)

```swift
@Observable @MainActor final class AppState {
    var currentScreen: AppScreen = .splash
    var capturedImage: UIImage?
    var renderedImage: UIImage?
    var analysisResult: AnalysisResult?       // didSet で LatestFaceMeshStore に landmarks を永続化
    var tutorialStep: Int = 0
    var tutorialDone: Bool = false
    var composition: MakeupComposition
    var activePresetID: String?
    var isRenderingMakeup: Bool = false
    var skipTutorialOnNextFlow: Bool = false  // Home Create からの直行フラグ
    let makeupEngine: MakeupEngineService
}
```

- `requestMakeupRender()`: 80ms debounce で `MakeupEngineService.render(composition:)` を実行、結果を `renderedImage` に反映。
- `runScreenshotFlow()`: `--screenshot-mode` 時に 8 画面を 3 秒間隔で巡回（モック画像＋mock 結果）。
- `reset()` で全状態クリア＋ `makeupEngine.reset()`。

---

## 13. UI/UX 改修ログ（Phase A〜C）

Nielsen の 10 原則 / WCAG / iOS HIG / 認知負荷理論 をベースに洗い出した
P0〜P2 課題を、3 フェーズに分けて適用した。

### Phase A — 文言・ラベルの和文化（コミット d83ca36 / a06911a）

「マガジン世界観のための装飾英語」と「機能ラベル」を切り分け、後者を
日本語＋SF Symbols に統一。装飾英語（`CHAPTER 07 · RESULT`、`step one.`、
`FIG. 01` 等）はブランドのために残す。

| Before | After |
|---|---|
| Home タブ `REPORT / CREATE / ARCHIVE` | `診断 / 撮影 / 保存`（SF Symbols 併用） |
| Diagnosis `BEGIN COMPOSITION` / `Skip to fine tuning` | 「メイクを試してみる（5ステップのガイドに沿って進めます）」/「ガイドを飛ばしてスタジオへ（メイクの経験がある方向け）」※副題を追加 |
| Diagnosis `OPEN STUDIO` (skipTutorial時) | 「スタジオを開く（すぐにプリセットや細かい調整ができます）」 |
| 各画面 `← BACK` | `← 撮影に戻る` / `← ガイドに戻る` / `← 診断結果` 等、戻り先を明示 |
| Tutorial `NEXT ACT → / COMPOSE → / SKIP →` | `次のステップへ / スタジオで仕上げる / あとで` |
| Tutorial header `ACT III OF 5` | `ステップ 3 / 5` |
| Tutorial `INTENSITY` / `OFF · 50 · MAX` | `強さ` / `なし · ふつう · 最大` |
| Studio header `← REPORT / ATELIER · STUDIO / HOME →` | `← 診断結果 / スタジオ / ホーム` |
| Studio mode `COMPARE / FINE TUNE` | `比べる (Before/After) / 細かく調整 (色味と強さ)` |
| Studio Bottom `♥ ARCHIVE THIS LOOK` / `↑` | `♥ このルックを保存` / `square.and.arrow.up` |
| Studio Toast `✓ LOOK ARCHIVED` | `✓ 保存しました` + ホームへ案内 |
| Studio Image `FIG. A — BEFORE / FIG. B — AFTER` | `Before · 素のまま / After · メイク後` |
| Studio Image `RENDERING…` | `反映中…` + ProgressView |
| Studio Image `SCORE 70` | `スコア 70` |
| FineTune `BASE / HIGHLIGHT / SHADOW / EYESHADOW / TEAR BAG / EYELINER` | `ベース / ハイライト / シェーディング / アイシャドウ / 涙袋 / アイライン` |
| FineTune `BROW TYPE` / `OFF · NATURAL · ARCH …` | `眉のかたち / なし · ナチュラル · 角度あり …` |
| Onboarding `SKIP →` | `読み飛ばす` |
| Onboarding `BEGIN →` | `撮影をはじめる` |
| Onboarding folio `p. 003 of 053` | `3 / 53 ページ` |
| Analyzing phases `PREPARING / DETECTING FACE / …` | `準備中 / 顔を検出中 / 比率を測定中 / 完了`、進捗番号 `(2/5)` 付き |
| Analyzing 「analysing…」「your facial geometry」 | 「解析しています」「顔の比率と骨格を測っています。10〜20 秒ほどかかります。」 |
| Home Create `compose. / 新しいルック.` | 「メイクを試す」+ `1 撮影 → 2 診断 → 3 メイク` の流れ表示 |
| Home Report `your face. / 評価レポート.` | 「診断レポート」、空状態に face.dashed アイコン |
| Home Archive `your archive.` `N looks saved` | 「マイ・コレクション」「保存 N 件」 |
| SavedLook 詳細 `HIGHLIGHT / SHADOW / EYE / BROW / INTENSITY` | `ハイライト / シェーディング / 目元 / 眉のかたち / 強さ` |
| SavedLook `40pt` | `40 点` |

合わせて全インタラクティブ要素に **日本語の `accessibilityLabel`** を付与し、
VoiceOver で装飾英語が読み上げられる事故を回避。

### Phase B — 不可逆操作の安全網（コミット a06911a / 837d7bf）

| 課題 | 対策 |
|---|---|
| **B1**: SavedLook の削除が確認ダイアログなしで即実行されデータ損失リスク | `SavedLookDetailSheet` に `.confirmationDialog` を追加。「このルックを削除しますか？削除すると元に戻せません。」+「削除する（destructive）/ キャンセル」 |
| **B2**: Analyzing でエラー (撮影失敗/顔検出失敗) になると戻る手段なし＝詰み | `AnalyzingView` にエラー状態専用画面を追加：原因＋対処を明文化、「もう一度撮影する」(プライマリ) / 「撮影画面に戻る」(セカンダリ) の 2 ボタン |
| **B3**: Studio で composition をいじった後「全部リセット」「直前に戻す」ができない | `StudioViewModel.resetAll()` を実装、モード行の右端に「リセット」ボタン（`arrow.counterclockwise`）を配置。`hasAnyIntensity` のときのみ有効化、`.confirmationDialog` で 1 段ガード |
| **B4**: ARCHIVE 後 1.4 秒で勝手に Home に飛び、もう一度直したいユーザーに不親切 | 自動遷移を廃止、Toast に「編集を続ける」「ホームへ」の 2 ボタンを置きユーザーが行き先を選ぶ。`StudioViewModel.dismissSavedNotification()` 追加 |

合わせて Maestro flows (`archive_flow.yaml` / `share_flow.yaml`) を新しい
動線に追従（`studio_saved_go_home` をタップして Home へ）。

新規 accessibilityIdentifier:
- `analyzing_retry_button` / `analyzing_back_button`
- `studio_reset_button`
- `studio_saved_keep_editing` / `studio_saved_go_home`

### Phase C — Studio の構造改修（コミット 63e7de1）

| 課題 | 対策 |
|---|---|
| **C1**: Fine Tune に 6 スライダー + 6 眉タイプ ＝ 12 個の制御が並びオーバーホエルム | Progressive Disclosure 化：既定で `肌 / 光 / 影 / 目元 + 眉のかたち` の 5 制御。「涙袋やアイラインも調整する」アコーディオンで残り 2 つを開示 |
| **C2**: プリセット名 (ナチュラル / Kスタイル等) だけでは仕上がりが想像できない | 各プリセットカードに **4 軸 (肌/光/影/目) のミニ縦バー** を追加。適用前に視覚で比較可能。`accessibilityLabel` には「肌 22、光 18、影 14、目 12」を生成して VoiceOver でも比較可 |
| **C3**: Compare の Before/After スライダーが中央 (0.5) で止まっていて、どっちが After か瞬時に分からない | 初回表示時に `comparePosition` を 0.5→0.25→0.75→0.5 と自動アニメ。戻った位置で「中央をドラッグして比べる」ヒントを 2.5 秒表示。`@State didPlayCompareIntro` で 1 回限り |

新規 accessibilityIdentifier:
- `studio_finetune_disclosure`

### 未着手 / 次のステップ

| 優先 | 課題 | メモ |
|---|---|---|
| P1 | フォントサイズ最小 9pt → 11pt 引き上げ | WCAG 観点。装飾フォリオ等は除く |
| P2 | Onboarding 53 ページの章ジャンプ＋後からアクセス | Profile 画面が無いので作るところから |
| P3 | Dynamic Type / Reduce Motion 対応 | アプリ全体に波及するので別 PR |
| P3 | NavigationStack 採用（エッジスワイプ戻り対応） | 既存の AppState 駆動ナビからのリアーキ |
