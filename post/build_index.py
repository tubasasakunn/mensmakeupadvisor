#!/usr/bin/env python3
"""各投稿の本文・ハッシュタグ・画像リストを index.json に書き出し、manifest.json を更新する。

  使い方: cd post && python3 build_index.py

- 画像リストは post/<postId>/<platform>/*.png を名前順で自動収集する
  （先に build_posts.py を実行しておく）。
- COPY に投稿ごとの文言（tiktok / lemon8）を定義する。
- manifest.json は公開スタジオ（任意・front 側の /post/）が読む一覧。
"""

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent

# MARK: - 文言（ここを編集して投稿を足す）
# TikTok: 冒頭フック→本文→CTA。タグ 3〜5。
# Lemon8: 掴み / 箇条書き▶ / まとめ / CTA。タグ最大 10（大中小 3:4:3 で混ぜる）。

COPY = {
    "post1": {
        "tiktok": {
            "title": "（冒頭フック）気づいたら毎日が残ってた話",
            "body": (
                "ここに本文。\n"
                "アプリで何ができるかを 2〜3 行で。\n\n"
                "ダウンロードはプロフィールのリンクから。"
            ),
            "hashtags": ["#タグ1", "#タグ2", "#タグ3"],
        },
        "lemon8": {
            "title": "（掴み）こんな人におすすめ",
            "body": (
                "掴みの一文。\n\n"
                "▶ ポイント1\n"
                "▶ ポイント2\n"
                "▶ ポイント3\n\n"
                "まとめの一文。\n"
                "プロフィールのリンクから。"
            ),
            "hashtags": [
                "#大タグ1", "#大タグ2", "#大タグ3",
                "#中タグ1", "#中タグ2", "#中タグ3", "#中タグ4",
                "#小タグ1", "#小タグ2", "#小タグ3",
            ],
        },
    },
}


def collect_images(post_id, platform):
    out = HERE / post_id / platform
    if not out.is_dir():
        return []
    return [p.name for p in sorted(out.glob("*.png"))]


def main():
    manifest = {"posts": []}
    for post_id in sorted(COPY):
        entry = {"id": post_id, "platforms": {}}
        for platform, copy in COPY[post_id].items():
            images = collect_images(post_id, platform)
            index = {
                "title": copy["title"],
                "body": copy["body"],
                "hashtags": copy["hashtags"],
                "images": images,
            }
            out = HERE / post_id / platform
            out.mkdir(parents=True, exist_ok=True)
            (out / "index.json").write_text(
                json.dumps(index, ensure_ascii=False, indent=2), encoding="utf-8")
            print("wrote", out / "index.json", f"({len(images)} images)")
            entry["platforms"][platform] = {
                "title": copy["title"], "count": len(images)}
        manifest["posts"].append(entry)
    (HERE / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    print("wrote", HERE / "manifest.json")


if __name__ == "__main__":
    main()
