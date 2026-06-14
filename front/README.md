# front/ ── Tone ランディングページ（Cloudflare Workers）

Tone（メンズメイク診断アプリ）の公式サイト。**Hono + Vite** で書き、**Cloudflare Workers** に
デプロイする。ドメインは `https://tone.basaapp.com`。

App Store の `marketing_url` / `support_url` / `privacy_url`（`release/<version>/`）はこのサイトを指す。

## ルート

| パス | 内容 | 実装 |
|---|---|---|
| `/` | ランディングページ | `src/site.ts` `homePage()` |
| `/privacy` | プライバシーポリシー（App Store 必須） | `privacyPage()` |
| `/support` | サポート / FAQ（App Store 必須） | `supportPage()` |
| `/hero.png` 他 | 画像 | `public/`（wrangler assets が配信） |

`/privacy.html` `/support.html` `/index.html` は旧 GitHub Pages 形式から 301 リダイレクト。

## 構成

- `src/index.ts` … Hono アプリ（ルーティング）。Workers のエントリ。
- `src/site.ts` … 各ページの HTML（`hono/html` テンプレート）。
- `src/styles.ts` … ブランド配色（アプリのダーク×ウォームラグジュアリーと一致）。
- `public/` … 静的画像。`appstore.config.json` の `brand` と `material/` 由来。
- `wrangler.jsonc` … Worker 名・assets・カスタムドメイン。

## 開発

```bash
cd front
npm install
npm run dev        # http://localhost:5173
```

## デプロイ

```bash
cd front
npx wrangler login           # 初回のみ（Cloudflare アカウント認証）
npm run deploy               # vite build → wrangler deploy
```

### カスタムドメイン（初回）

`wrangler.jsonc` の `routes` に `tone.basaapp.com` を `custom_domain: true` で宣言済み。
**`basaapp.com` ゾーンが同じ Cloudflare アカウントにあること**が前提。`wrangler deploy` 時に
`tone.basaapp.com` のレコードと証明書が自動でこの Worker に割り当てられる。
別アカウントの場合は、先に `basaapp.com` を Cloudflare に追加するか、ダッシュボードの
Workers Routes / Custom Domains から手動で紐付ける。

## 画像の更新

`public/*.png` の正本は、ストア画像生成と同じ素材：

```bash
# 例：ヒーロー画像をストア用 01_hero と揃える
cp ../release/1.0/img/01_hero.png public/hero.png
cp ../material/app_icon_1024.png public/icon.png
```
