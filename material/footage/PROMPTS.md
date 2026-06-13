# footage/ ── クロマキー差し込み用フッテージの生成プロンプト

ストア画像・SNS 画像のクロマキー領域（動画・画像が映る部分）に入れる
「ユーザーが撮った日常」風の画像を、画像生成 AI で作るときのプロンプト集。
`store_slides.json` の `footage` キー（例 `hero` / `core` / `detail` / `review`）と
同じ名前で画像（png / jpg / webp）を置くと、`scripts/make_store_images.py` が
フラットイラストの代わりに採用する（アスペクトフィルで中央クロップ／構図は中央寄せ）。

## 共通の方針（アプリの世界観に合わせて編集）

- **縦 9:16**（フル画面用は 1206×2622 以上が理想）
- **スマホで撮った何気ない 1 フレーム**に見えること。作品然とした構図・プロの
  ライティングは避ける
- プライバシー志向アプリなら**顔は写さない**（手元・後ろ姿・風景のみ）
- トーンはアプリのカラーグレード（例：暖色）に合わせる
- 文字・ロゴ・ウォーターマークなし

共通サフィックス（各プロンプトの末尾に付ける・例）：

> vertical 9:16, candid smartphone video still, casual amateur framing,
> warm film-like color grade, soft natural light, photorealistic,
> no people's faces, no text, no watermark

ネガティブプロンプト（対応している生成系で）：

> text, watermark, logo, human face, oversaturated colors, HDR look,
> professional studio lighting, tilt-shift, illustration, anime

## 各ファイルのプロンプト（例・要編集）

### hero（主役画面・フル画面）

> （アプリの主役体験を象徴する 1 フレーム。例：夕方の帰り道・golden hour）

狙い：ヒーロー画像。UI（チップ・ボタン）と被写体の重なりを避け、主役は中央〜上。

### core（コア操作・フル画面）

> （いま操作しようとしている瞬間の景色）

狙い：ボタンが下部に重なるので地面寄りは余白、中央に被写体。

### detail / review（小サムネ）

> （手元・寄りの被写体を 1 つ大きく）

狙い：小さく表示されるので被写体は大きく単純に。色域を他スライドと分散させる。

## 差し替え後の手順

```bash
python3 scripts/make_store_images.py
```

を再実行し、`release/<version>/img/` を目視確認（観点は `/release-assets` スキル）。
特にフル画面のスライドは UI と被写体の重なりを見る。
