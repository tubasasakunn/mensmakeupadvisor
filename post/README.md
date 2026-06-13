# post/ ── SNS カルーセル投稿（複数画像）

TikTok（1080×1920 / 9:16）と Lemon8（1080×1440 / 3:4）向けの**複数画像投稿**を作る。
動画ではなく画像を複数枚並べる投稿（カルーセル）が対象。

- 描画エンジン：`_brand.py`（ブランド共通の部品。色・ワードマークは `appstore.config.json`）
- 画像の内容定義：`build_posts.py` の `POSTS`
- 本文・タグ：`build_index.py` の `COPY`
- 装飾モチーフ：`assets/svg/*.svg`（依存ゼロの自前レンダラ `_brand.svg_image`）

## プラットフォーム仕様（最新は各社ヘルプで確認）

| | サイズ | 比 | 枚数 | タグ | 安全域 |
|---|---|---|---|---|---|
| TikTok | 1080×1920 | 9:16 | 5〜35 | 3〜5 | 下 1/3 に文字を置かない |
| Lemon8 | 1080×1440 | 3:4 | 〜20 | 〜10 | 下端は控えめ |

## スライド 5 種

| type | 役割 | 主なフィールド |
|---|---|---|
| `cover` | 表紙（フッテージ全面 + フック） | `bg`, `kicker`, `headline` |
| `photo` | 共感・日常（フッテージ + キャプション） | `bg`, `caption`, `note` |
| `shot` | アプリ実画面（端末モック・緑差替え） | `shot`, `footage`, `title`, `sub` |
| `info` | 情報カード（保存されやすい） | `kicker`, `title`, `bullets` |
| `cta` | 締め（ワードマーク + 誘導） | `headline`, `sub`, `store` |

構成テンプレ：**表紙（フック）→ 共感/日常 → アプリ実画面（証拠）→ ノウハウ/機能 → CTA**。

## デザイン方針（エディトリアル）

左寄せ・セリフ見出し（Noto Serif JP）＋サンス本文＋モノラベル/番号の三層タイポ、
フィルム枠ティック・ヘアライン罫・微細グレインで質感を統一する。中央揃え・白カード・
塗りピル・一律ドロップシャドウは**使わない**（量産デザインの兆候）。
モチーフは `assets/svg/*.svg` を単色ラスタライズして使う（cairosvg 等は入れない）。

## 生成

```bash
# 初回のみ：見出しフォント取得は build_posts.py が自動で行う（要ネットワーク）
pip3 install Pillow numpy

cd post
python3 build_posts.py   # 画像（両プラットフォーム）
python3 build_index.py   # 本文・タグ・images・manifest.json
```

出力：`post/<postId>/{tiktok,lemon8}/NN_*.png` と `index.json`。
生成後は**必ず目視確認**（Read で画像を開く）。崩れ・はみ出し・読みにくさがあれば
`POSTS` の文言量や `accent` を調整して再生成。

## フッテージ

表紙・共感スライドの背景は `material/footage/<name>.(jpg|png)` を `POSTS` の `bg` で参照する。
無ければアクセント単色で埋まる（プレースホルダ）。実写風フッテージの生成プロンプトは
`material/footage/PROMPTS.md`。**投稿ごとに表紙の背景を変える**と 1 枚目が差別化される。

## 投稿一覧

### post1 ── （切り口をここに）

スライド構成・両プラットフォームのタイトル/タグは `build_posts.py` の `POSTS["post1"]` と
`build_index.py` の `COPY["post1"]` を参照。新しい投稿は `postN` を両方に足す。

## 運用メモ

- 直リンクは本文に貼らず「プロフィールのリンクから」へ誘導（Lemon8 は商用直リンクを避ける）。
- 公式と分かるアカウント前提なら PR 表記は必須ではない（各国のステマ規制は別途確認）。
- `__pycache__` が出たら消す（`rm -rf post/__pycache__`）。
