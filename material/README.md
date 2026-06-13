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

## ファイル一覧（例・アプリに合わせて編集）

| ファイル | 画面 |
|---|---|
| `screen-hero.png` | アプリの主役画面（フル画面・クロマキー領域あり） |
| `screen-core.png` | コア操作の画面 |
| `screen-detail.png` | 入力・詳細画面 |
| `screen-review.png` | 一覧・振り返り画面 |
| `screen-privacy.png` | 設定・ロック・プライバシー系 |

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
