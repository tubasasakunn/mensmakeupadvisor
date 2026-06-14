import { defineConfig } from "vite";
import build from "@hono/vite-build/cloudflare-workers";
import devServer from "@hono/vite-dev-server";
import adapter from "@hono/vite-dev-server/cloudflare";

// Hono を Cloudflare Workers 向けにバンドルする。
// 静的画像（public/）は wrangler の assets が配信し、HTML ルートは Worker が処理する。
export default defineConfig({
  plugins: [
    build({ entry: "src/index.ts" }),
    devServer({ entry: "src/index.ts", adapter }),
  ],
});
