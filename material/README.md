# material/ ── 画面スクリーンショット素材

アプリ全画面のスクリーンショット集。LP・ストア素材・デザイン検討用。Debug ビルドで取得し、
`scripts/make_store_images.py` と `post/`（SNS カルーセル）が元素材として使う。

- 直下：iPhone のシミュレータ（例 iPhone 17 Pro / 1206×2622px @3x）
- `ipad13/`：iPad Pro 13-inch のシミュレータ（例 2064×2752px @2x）。
  ファイル名・画面の対応は iPhone 版と同一。

スクショの実ファイル（.png）はアプリごとに撮るのでこのテンプレートには含めない。
`store_slides.json` が参照する名前（`screen-hero.png` 等）でここに置く。

## 動画・画像モックのクロマキー色（重要）

**動画・画像・サムネイルが映る領域はすべて単色モック `#00FF00`（純緑 / RGB 0,255,0）で
固定**しておくと、`make_store_images.py` がクロマキー（透過処理）でくり抜き、任意の
映像・画像を合成できる。スクショを撮る前に、アプリ側（Debug シード等）で該当領域を
純緑に塗る仕掛けを用意しておく。

- 注意 1：動画ファイル経由の領域は H.264（4:2:0）を通ると境界画素がわずかに揺れる。
  キーイングは完全一致でなく ±数% の許容幅を持たせている（実装は `key_out_green`）。
- 注意 2：シートの暗幕（scrim）が映像領域に重なると緑が沈んでキーが抜けない。
  素の映像領域が必要な面は scrim の無い状態で別に撮る。

## ファイル一覧（全画面スクショ・iPhone 16e / iOS 26）

ハッピーパス（起動 → オンボーディング → 撮影 → 解析 → 診断 → チュートリアル →
スタジオ → 保存 → ホーム → 履歴 → 推移）を一周しながら採取。番号は遷移順。

| ファイル | 画面 |
|---|---|
| `01_splash.png` | スプラッシュ（起動直後・短命） |
| `02_onboarding.png` | オンボーディング（全 53 ページの 1 ページ目） |
| `03_capture.png` | 撮影（キャプチャ）画面 |
| `04_analyzing.png` | 解析中（顔比率・骨格計測） |
| `05_diagnosis_top.png` | 診断結果トップ（スコアリング・顔型） |
| `06_diagnosis_mesh.png` | 診断: フェイスメッシュ可視化 |
| `07_diagnosis_proportions.png` | 診断: 比率プレート＋7 項目詳細レポート |
| `08_tutorial.png` | チュートリアル（5 ステップのガイド・強度スライダー） |
| `09_studio.png` | スタジオ（Before/After 比較・スコア） |
| `10_studio_arrange_compare.png` | スタジオ > アレンジ: プリセット比較 |
| `11_studio_arrange_color.png` | スタジオ > アレンジ: カラー調整 |
| `12_mirror.png` | ミラーモード（モック表示） |
| `13_save_title_sheet.png` | 保存タイトルシート（送り出し前） |
| `14_completion.png` | 完了（送り出し） |
| `15_home.png` | ホーム（撮影タブ） |
| `16_archive.png` | ホーム > 保存（アーカイブ・マイコレクション） |
| `17_progress.png` | スコア推移（あなたの軌跡） |

再取得は `.maestro/flows/all_screens_capture_flow.yaml`。手順は本ファイル末尾「再取得の手順」を参照。

## 再取得の手順（Debug ビルドの環境変数フック方式）

Debug ビルドにディープリンク的な「特定画面を直接開く」環境変数フックを仕込んでおくと、
CLI から各画面を確実に開いて撮れる（手動操作のばらつきを排除）。

```bash
# 例：環境変数で画面を指定して起動 → スクショ
xcrun simctl launch booted <bundle id>            # SIMCTL_CHILD_<VAR> でフック値を渡す
xcrun simctl io booted screenshot screen-hero.png
```

App Store Connect は解像度でシェルフを判定するので、**ストア用は横向きへ合成する前の
素材**としてここに置き、サイズ確定は `make_store_images.py` 側で行う。

## footage/

クロマキー領域に差し込む「実写風フッテージ」を置く場所。プロンプトは
`footage/PROMPTS.md`。`store_slides.json` の `footage` キー（`hero` 等）に対応する
名前で png/jpg/webp を置くと、フラットイラストの代わりに自動採用される。
