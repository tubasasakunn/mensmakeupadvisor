#!/usr/bin/env python3
"""SNS カルーセル画像を一括生成する（TikTok 9:16 / Lemon8 3:4）。

スライドの中身は POSTS に定義する。描画基盤は _brand.py。
ブランド色・ワードマークは ../appstore.config.json。

  使い方: cd post && python3 build_posts.py

出力: post/<postId>/{tiktok,lemon8}/NN_*.png
両プラットフォームを同じ POSTS から出し分ける（renderer が安全域を吸収）。
スライド 5 種：cover / photo / shot / info / cta。
新しい投稿は POSTS に "postN" を足すだけ（README の手順参照）。
"""

from pathlib import Path

from PIL import Image, ImageDraw

import _brand as B

ROOT = Path(__file__).resolve().parent.parent
HERE = Path(__file__).resolve().parent
MATERIAL = ROOT / "material"

# プラットフォーム仕様（最新は post/README.md の表が正本）
PLATFORMS = {
    "tiktok": {"size": (1080, 1920), "safe_bottom": 0.30},  # 下 1/3 に文字を置かない
    "lemon8": {"size": (1080, 1440), "safe_bottom": 0.12},
}

MARGIN = 80


# MARK: - フッテージ解決

def footage_path(name):
    """material/footage/<name>.(jpg|png|jpeg|webp) を返す。無ければ None。"""
    if not name:
        return None
    for ext in ("jpg", "png", "jpeg", "webp"):
        p = MATERIAL / "footage" / f"{name}.{ext}"
        if p.exists():
            return p
    return None


def footage_or_solid(name, size, accent):
    """フッテージがあれば cover-crop、無ければアクセントの単色で埋める。"""
    p = footage_path(name)
    if p:
        return B.cover_crop(Image.open(p), size[0], size[1]).convert("RGBA")
    base = Image.new("RGBA", size, accent + (255,))
    B.grain(base, seed=7, amount=20)
    return base


# MARK: - スライド renderer（type ごと）

def render_cover(size, spec, accent, idx, total):
    w, h = size
    bg = footage_or_solid(spec.get("bg"), size, accent)
    bg.alpha_composite(B.bottom_scrim(w, h, start=0.32, bot_a=210))
    B.frame_ticks(bg, (255, 255, 255), alpha=130)
    d = ImageDraw.Draw(bg)
    # キッカー（モノラベル）
    if spec.get("kicker"):
        B.tick_label(bg, spec["kicker"], MARGIN, int(h * 0.10),
                     (255, 255, 255), accent, size=34)
    # セリフ見出し（左寄せ・下からせり上げ）
    lines = spec["headline"].split("\n")
    f = B.serif_font(118, 600)
    leading = 138
    top = h * (1 - PLATFORMS_safe(spec)) - len(lines) * leading - 220
    B.draw_lines(d, lines, f, (255, 255, 255), MARGIN, top, leading, align="left")
    # ワードマーク + ページ index
    B.wordmark(bg, MARGIN, int(h * 0.10) - 4, 56, ink=(255, 255, 255), anchor="l") \
        if not spec.get("kicker") else None
    B.index_tag(bg, idx, total, w - MARGIN, int(h * 0.10), (255, 255, 255), anchor="r")
    return bg


def render_photo(size, spec, accent, idx, total):
    w, h = size
    bg = footage_or_solid(spec.get("bg"), size, accent)
    bg.alpha_composite(B.bottom_scrim(w, h, start=0.45, bot_a=200))
    d = ImageDraw.Draw(bg)
    lines = spec["caption"].split("\n")
    f = B.serif_font(72, 500)
    leading = 96
    top = h * (1 - PLATFORMS_safe(spec)) - len(lines) * leading - 120
    B.draw_lines(d, lines, f, (255, 255, 255), MARGIN, top, leading, align="left")
    if spec.get("note"):
        nf = B.font(40, 500)
        d.text((MARGIN, top + len(lines) * leading + 16), spec["note"],
               font=nf, fill=(255, 255, 255))
    B.index_tag(bg, idx, total, w - MARGIN, int(h * 0.06), (255, 255, 255), anchor="r")
    return bg


def render_shot(size, spec, accent, idx, total):
    w, h = size
    canvas = Image.new("RGBA", size, B.BG + (255,))
    B.soft_blob(canvas, accent, w // 2, int(h * 0.42))
    shot = Image.open(MATERIAL / spec["shot"])
    fp = footage_path(spec.get("footage"))
    if fp:
        shot = B.key_out_green(shot, B.footage_scene(fp))
    phone = B.phone_mockup(shot)
    target_h = int(h * 0.52)
    B.paste_phone_shadow(canvas, phone, w // 2, int(h * 0.13), target_h)
    d = ImageDraw.Draw(canvas)
    # タイトル + サブ（下部）
    ty = int(h * 0.13) + target_h + 60
    tf = B.serif_font(78, 600)
    B.draw_lines(d, spec["title"].split("\n"), tf, B.INK, MARGIN, ty, 96, align="left")
    if spec.get("sub"):
        sy = ty + len(spec["title"].split("\n")) * 96 + 14
        B.draw_lines(d, spec["sub"].split("\n"), B.font(42, 450), B.SUB_INK,
                     MARGIN, sy, 60, align="left")
    B.hairline(canvas, MARGIN, int(h * 0.10), w - MARGIN)
    B.index_tag(canvas, idx, total, w - MARGIN, int(h * 0.065), B.SUB_INK, anchor="r")
    B.grain(canvas, seed=idx)
    return canvas


def render_info(size, spec, accent, idx, total):
    w, h = size
    canvas = Image.new("RGBA", size, B.BG + (255,))
    B.frame_ticks(canvas, B.INK, alpha=40)
    d = ImageDraw.Draw(canvas)
    if spec.get("kicker"):
        B.tick_label(canvas, spec["kicker"], MARGIN, int(h * 0.10), B.SUB_INK, accent, size=34)
    ty = int(h * 0.17)
    tf = B.serif_font(96, 600)
    ty = B.draw_lines(d, spec["title"].split("\n"), tf, B.INK, MARGIN, ty, 116, align="left")
    B.hairline(canvas, MARGIN, ty + 30, w - MARGIN, alpha=60)
    by = ty + 90
    bf = B.font(52, 500)
    for i, bullet in enumerate(spec["bullets"]):
        B.paste_svg(canvas, "sparkle", MARGIN, by + 6, 36, accent)
        for ln in bullet.split("\n"):
            d.text((MARGIN + 60, by), ln, font=bf, fill=B.INK)
            by += 70
        by += 24
    B.index_tag(canvas, idx, total, w - MARGIN, int(h * 0.10), B.SUB_INK, anchor="r")
    B.grain(canvas, seed=idx)
    return canvas


def render_cta(size, spec, accent, idx, total):
    w, h = size
    canvas = Image.new("RGBA", size, B.BG + (255,))
    B.soft_blob(canvas, accent, w // 2, int(h * 0.55), r=560, alpha=60)
    B.frame_ticks(canvas, B.INK, alpha=40)
    B.wordmark(canvas, w // 2, int(h * 0.22), 96, anchor="c")
    d = ImageDraw.Draw(canvas)
    hf = B.serif_font(92, 600)
    hy = int(h * 0.40)
    hy = B.draw_lines(d, spec["headline"].split("\n"), hf, B.INK, w // 2, hy, 112,
                      align="center")
    if spec.get("sub"):
        B.draw_lines(d, spec["sub"].split("\n"), B.font(46, 450), B.SUB_INK,
                     w // 2, hy + 30, 64, align="center")
    # App Store 誘導
    store = spec.get("store", f"App Store で「{B.WORDMARK}」")
    B.paste_svg(canvas, "arrow", w // 2 - 120, int(h * 0.72), 40, accent, anchor="l")
    d.text((w // 2, int(h * 0.76)), store, font=B.font(50, 600), fill=B.INK,
           anchor="ma")
    B.grain(canvas, seed=idx)
    return canvas


RENDERERS = {
    "cover": render_cover, "photo": render_photo, "shot": render_shot,
    "info": render_info, "cta": render_cta,
}


def PLATFORMS_safe(spec):
    # spec 描画時に現在のプラットフォーム safe_bottom を参照する（_CURRENT に格納）
    return _CURRENT["safe_bottom"]


_CURRENT = {}


# MARK: - 投稿定義（ここを編集して投稿を足す）

POSTS = {
    "post1": {
        "accent": "evening",
        "slides": [
            {"type": "cover", "bg": "hero", "kicker": "── はじめての投稿",
             "headline": "ここに\nフックを。"},
            {"type": "photo", "bg": "core",
             "caption": "共感・日常の\n一コマをここに。", "note": "あなたの切り口で"},
            {"type": "shot", "shot": "screen-hero.png", "footage": "hero",
             "title": "アプリの実画面。", "sub": "証拠になる本物のスクショを見せる。"},
            {"type": "info", "kicker": "── できること",
             "title": "保存されやすい\n情報カード。",
             "bullets": ["ポイント 1 を簡潔に", "ポイント 2", "ポイント 3"]},
            {"type": "cta", "headline": "今日から、はじめよう。",
             "sub": "無料でダウンロード"},
        ],
    },
}


def build(post_id, platform):
    spec = POSTS[post_id]
    plat = PLATFORMS[platform]
    _CURRENT.clear()
    _CURRENT.update(plat)
    size = plat["size"]
    accent_name = spec.get("accent", "evening")
    slides = spec["slides"]
    total = len(slides)
    out = HERE / post_id / platform
    out.mkdir(parents=True, exist_ok=True)
    for f in out.glob("*.png"):
        f.unlink()
    for i, sl in enumerate(slides, start=1):
        accent = B.ACCENTS[sl.get("accent", accent_name)]
        img = RENDERERS[sl["type"]](size, sl, accent, i, total)
        name = f"{i:02d}_{sl['type']}.png"
        img.convert("RGB").save(out / name)
        print("wrote", out / name)


def main():
    B.ensure_fonts()
    for post_id in POSTS:
        for platform in PLATFORMS:
            build(post_id, platform)


if __name__ == "__main__":
    main()
