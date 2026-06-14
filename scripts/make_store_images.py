#!/usr/bin/env python3
"""App Store 用スクリーンショット画像（横向き）を生成する。

material/ のスクリーンショット（動画・画像領域は #00FF00 のクロマキー）を
端末モックアップに収め、見出し・アプリアイコングリフ・フラットイラストの
ダミー映像を合成して release/<version>/img/ に出力する。

  使い方: python3 scripts/make_store_images.py [version]
          version 省略時は appstore.config.json の xcodeproj の MARKETING_VERSION

ブランド（色・ワードマーク）は appstore.config.json、スライド構成は
scripts/store_slides.json から読む。アプリ固有の作り込みはこの 2 ファイルで完結する。

依存: Pillow, numpy（pip install Pillow numpy）
日本語見出しフォントは Noto Sans JP（可変フォント）を実行時に取得する。
"""

import json
import math
import subprocess
import sys
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

from _config import get

ROOT = Path(__file__).resolve().parent.parent
MATERIAL = ROOT / "material"

# MARK: - ブランド（appstore.config.json）

BG = tuple(get("brand", "bg", default=[247, 244, 240]))
INK = tuple(get("brand", "ink", default=[42, 37, 32]))
SUB_INK = tuple(get("brand", "sub_ink", default=[111, 103, 96]))
ACCENTS = {k: tuple(v) for k, v in get("brand", "accents", default={
    "morning": [232, 168, 124], "forenoon": [242, 201, 76],
    "afternoon": [168, 197, 160], "evening": [224, 123, 84],
    "night": [155, 114, 207], "midnight": [91, 127, 166],
}).items()}
ICON_COLOR = tuple(get("brand", "icon_color", default=[197, 111, 82]))
WORDMARK = get("brand", "wordmark", default=get("app", "name", default="App"))

NOTO = Path("/tmp/NotoSansJP.ttf")
NOTO_URL = get("fonts", "jp_sans_url", default=(
    "https://raw.githubusercontent.com/google/fonts/main/"
    "ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf"))
_latin = get("fonts", "latin_sans_ttf", default="")
LATIN_SANS = (ROOT / _latin) if _latin else NOTO  # 無ければ Noto で代用

CANVAS_DEFAULT = (2868, 1320)

# デバイスごとの素材・キャンバス・レイアウト定義。
# スクショは App Store Connect が解像度でシェルフを判定するため、
# サイズは 1px も変えないこと（iPhone 6.9": 2868x1320 / iPad 13": 2752x2064）
DEVICES = {
    "iphone": {
        "canvas": (2868, 1320),
        "material": None,        # MATERIAL 直下
        "prefix": "",
        "target_h": 1190,        # モックアップの表示高
        "screen_r": 186,         # 画面角丸（@3x 相当）
        "bezel": 34,
        "phone_cx": (2128, 740),  # (右配置, 左配置) の中心 x
        "text_x": (200, 1500),    # (phone右→文左, phone左→文右) の x
        "scale": 1.0,
        "char_bottom": 110,
        "dots_y": 1120,
        "wordmark_y": 120,
        "blob_cy": 560,
    },
    "ipad13": {
        "canvas": (2752, 2064),
        "material": "ipad13",
        "prefix": "ipad_",
        "target_h": 1860,
        "screen_r": 84,          # iPad はベゼル一定・角丸小さめ（@2x 相当）
        "bezel": 56,
        "phone_cx": (1990, 745),
        # text-right の開始 x は端末の右端をかわしつつ、8 文字見出しが canvas 右端
        # （2752）に収まる位置。scale は iPhone と同じ 1.0（1.15 だと句点がはみ出す）。
        "text_x": (180, 1490),
        "scale": 1.0,
        "char_bottom": 170,
        "dots_y": 1800,
        "wordmark_y": 200,
        "blob_cy": 880,
    },
}


def out_dir() -> Path:
    version = sys.argv[1] if len(sys.argv) > 1 else marketing_version()
    return ROOT / "release" / version / "img"


def marketing_version() -> str:
    xcodeproj = get("app", "xcodeproj", default="App.xcodeproj")
    pbxproj = (ROOT / xcodeproj / "project.pbxproj").read_text()
    versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", pbxproj))
    if len(versions) != 1:
        sys.exit(f"MARKETING_VERSION が一意でない: {sorted(versions)}")
    return versions.pop()


def ensure_noto() -> None:
    if NOTO.exists():
        return
    subprocess.run(["curl", "-sL", "--max-time", "60", "-o", str(NOTO), NOTO_URL],
                   check=True)


def jp_font(size: int, weight: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(NOTO), size)
    try:
        font.set_variation_by_axes([weight])
    except OSError:
        pass  # FreeType が可変フォント非対応ならデフォルトウェイトで続行
    return font


# MARK: - フラットイラストのダミー映像（クロマキー領域の汎用フォールバック）

def _vgrad(size, stops):
    """縦方向の多段グラデーション。stops = [(pos0..1, (r,g,b)), ...]"""
    w, h = size
    img = Image.new("RGB", (1, h))
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
            if p0 <= t <= p1:
                f = (t - p0) / max(p1 - p0, 1e-6)
                px[0, y] = tuple(round(a + (b - a) * f) for a, b in zip(c0, c1))
                break
        else:
            px[0, y] = stops[-1][1]
    return img.resize((w, h))


def _blob(draw, cx, cy, rx, ry, color):
    draw.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=color)


def scene_sunset(size):
    """夕暮れの空と丘。ヒーロー面のダミー映像。"""
    w, h = size[0] * 2, size[1] * 2
    img = _vgrad((w, h), [(0.0, (255, 221, 166)), (0.45, (244, 168, 110)),
                          (0.8, (222, 120, 86)), (1.0, (205, 102, 78))])
    d = ImageDraw.Draw(img)
    _blob(d, w * 0.5, h * 0.40, w * 0.16, w * 0.16, (255, 238, 200))
    for cx, cy, s in [(0.22, 0.20, 1.0), (0.72, 0.13, 0.8), (0.55, 0.30, 0.6)]:
        cw = w * 0.13 * s
        _blob(d, w * cx, h * cy, cw, cw * 0.38, (255, 244, 226))
        _blob(d, w * cx + cw * 0.7, h * cy + cw * 0.12, cw * 0.7, cw * 0.3,
              (255, 244, 226))
    _blob(d, w * 0.18, h * 0.98, w * 0.65, h * 0.30, (171, 92, 73))
    _blob(d, w * 0.92, h * 1.02, w * 0.75, h * 0.34, (148, 78, 66))
    return img.resize(size, Image.LANCZOS)


def scene_morning(size):
    """朝の住宅街と空。"""
    w, h = size[0] * 2, size[1] * 2
    img = _vgrad((w, h), [(0.0, (193, 222, 233)), (0.5, (245, 233, 200)),
                          (1.0, (250, 222, 170))])
    d = ImageDraw.Draw(img)
    _blob(d, w * 0.30, h * 0.34, w * 0.11, w * 0.11, (255, 246, 214))
    ground_y = h * 0.62
    d.rectangle([0, ground_y, w, h], fill=(214, 196, 168))
    for hx, hw, hh, body in [(0.06, 0.26, 0.20, (236, 222, 204)),
                             (0.42, 0.24, 0.16, (226, 206, 182)),
                             (0.74, 0.28, 0.22, (240, 226, 206))]:
        x0, y1 = w * hx, ground_y
        x1, y0 = x0 + w * hw, ground_y - h * hh
        d.rectangle([x0, y0, x1, y1], fill=body)
        d.polygon([(x0 - w * 0.015, y0), (x1 + w * 0.015, y0),
                   ((x0 + x1) / 2, y0 - h * 0.05)], fill=(186, 124, 99))
    return img.resize(size, Image.LANCZOS)


def scene_coffee(size):
    """テーブルの上のコーヒー。小サムネ用。"""
    w, h = size[0] * 2, size[1] * 2
    img = _vgrad((w, h), [(0.0, (250, 236, 214)), (1.0, (242, 220, 190))])
    d = ImageDraw.Draw(img)
    d.rectangle([0, h * 0.62, w, h], fill=(206, 162, 128))
    d.ellipse([w * 0.16, h * 0.56, w * 0.84, h * 0.74], fill=(238, 228, 214))
    cup_w, cup_h = w * 0.40, h * 0.22
    cx0, cy0 = w * 0.30, h * 0.42
    d.rounded_rectangle([cx0, cy0, cx0 + cup_w, cy0 + cup_h],
                        radius=w * 0.05, fill=(255, 252, 246))
    d.ellipse([cx0 + cup_w * 0.12, cy0 + cup_h * 0.05,
               cx0 + cup_w * 0.88, cy0 + cup_h * 0.40], fill=(178, 120, 86))
    return img.resize(size, Image.LANCZOS)


def scene_park(size):
    """公園の緑。小サムネ用。"""
    w, h = size[0] * 2, size[1] * 2
    img = _vgrad((w, h), [(0.0, (214, 233, 242)), (0.55, (236, 242, 222)),
                          (1.0, (196, 216, 178))])
    d = ImageDraw.Draw(img)
    _blob(d, w * 0.74, h * 0.16, w * 0.10, w * 0.10, (255, 244, 198))
    _blob(d, w * 0.20, h * 0.78, w * 0.75, h * 0.28, (176, 203, 158))
    _blob(d, w * 0.95, h * 0.85, w * 0.8, h * 0.30, (158, 189, 142))
    x, ty = w * 0.32, h * 0.66
    d.rectangle([x - w * 0.012, ty - h * 0.10, x + w * 0.012, ty],
                fill=(140, 102, 78))
    _blob(d, x, ty - h * 0.13, w * 0.085, w * 0.095, (118, 158, 108))
    return img.resize(size, Image.LANCZOS)


SCENES = {"sunset": scene_sunset, "morning": scene_morning,
          "coffee": scene_coffee, "park": scene_park}


def footage_or(name, fallback):
    """material/footage/<name>.(png|jpg|jpeg|webp) があればそれを採用する。

    生成 AI で作ったフッテージ（プロンプトは material/footage/PROMPTS.md）を
    アスペクトフィル（中央クロップ）で bbox に合わせる。無ければ
    フラットイラストの fallback シーンで描く。
    """
    def scene(size):
        if name:
            for ext in ("png", "jpg", "jpeg", "webp"):
                path = MATERIAL / "footage" / f"{name}.{ext}"
                if path.exists():
                    img = Image.open(path).convert("RGB")
                    scale = max(size[0] / img.width, size[1] / img.height)
                    img = img.resize((round(img.width * scale),
                                      round(img.height * scale)), Image.LANCZOS)
                    x0 = (img.width - size[0]) // 2
                    y0 = (img.height - size[1]) // 2
                    return img.crop((x0, y0, x0 + size[0], y0 + size[1]))
        return fallback(size)
    return scene


# MARK: - クロマキー合成

def key_out_green(shot: Image.Image, scene_for_bbox) -> Image.Image:
    """#00FF00 領域を検出し、その bbox に合わせたシーンで置き換える。"""
    rgb = np.asarray(shot.convert("RGB")).astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    strength = g - np.maximum(r, b)  # 純緑で +255、通常 UI ではほぼ 0 以下
    # 半透明 UI（チップ・バー等）は緑が透けるので低めの閾値で拾い、
    # 置き換えで残った薄い緑かぶりはデスピル（G チャンネルの頭打ち）で消す
    alpha = np.clip((strength - 26) * (255 / 50), 0, 255).astype(np.uint8)
    ys, xs = np.nonzero(alpha > 128)
    if len(xs) == 0:
        return shot.convert("RGB")
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    scene = scene_for_bbox((int(x1 - x0), int(y1 - y0)))
    despilled = rgb.copy()
    despilled[..., 1] = np.minimum(g, np.maximum(r, b) + 24)
    base = Image.fromarray(despilled.astype(np.uint8), "RGB")
    mask = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(1.2))
    layer = Image.new("RGB", base.size)
    layer.paste(scene, (int(x0), int(y0)))
    base.paste(layer, (0, 0), mask)
    return base


# MARK: - 端末モックアップ

def phone_mockup(shot: Image.Image, screen_r=186, bezel=34) -> Image.Image:
    """スクショをベゼル付きの端末フレームに収める。"""
    sw, sh = shot.size
    pad = 16            # サイドボタンのはみ出しぶん
    body_w, body_h = sw + bezel * 2, sh + bezel * 2
    img = Image.new("RGBA", (body_w + pad * 2, body_h + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def btn(x0, y0, x1, y1):
        d.rounded_rectangle([x0, y0, x1, y1], radius=10, fill=(58, 58, 62, 255))

    btn(pad + body_w - 6, pad + body_h * 0.28, pad + body_w + 12,
        pad + body_h * 0.40)                                          # 電源
    btn(pad - 12, pad + body_h * 0.21, pad + 6, pad + body_h * 0.275)  # 音量上
    btn(pad - 12, pad + body_h * 0.29, pad + 6, pad + body_h * 0.355)  # 音量下
    d.rounded_rectangle([pad, pad, pad + body_w, pad + body_h],
                        radius=screen_r + bezel, fill=(23, 23, 26, 255))
    d.rounded_rectangle([pad + 6, pad + 6, pad + body_w - 6, pad + body_h - 6],
                        radius=screen_r + bezel - 6,
                        outline=(72, 70, 68, 255), width=3)

    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius=screen_r,
                                           fill=255)
    img.paste(shot.convert("RGB"), (pad + bezel, pad + bezel), mask)
    return img


# MARK: - アプリアイコングリフ（h キャラの代わりの汎用プレースホルダ）

def icon_glyph(height: int, color=ICON_COLOR) -> Image.Image:
    """アプリアイコンを角丸マスクして返す。

    material/app_icon_1024.png があれば実アイコンを採用し、無ければワードマーク
    頭文字のプレースホルダにフォールバックする。
    """
    ss = 4
    size = height * ss
    radius = int(size * 0.22)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, size, size], radius=radius, fill=255)

    real = MATERIAL / "app_icon_1024.png"
    if real.exists():
        src = Image.open(real).convert("RGBA").resize((size, size), Image.LANCZOS)
        img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        img.paste(src, (0, 0), mask)
        return img.resize((height, height), Image.LANCZOS)

    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size, size], radius=radius, fill=color + (255,))
    letter = (WORDMARK[:1] or "A").upper()
    f = ImageFont.truetype(str(LATIN_SANS), int(size * 0.62))
    bbox = d.textbbox((0, 0), letter, font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - tw) / 2 - bbox[0], (size - th) / 2 - bbox[1]), letter,
           font=f, fill=(255, 255, 255, 235))
    return img.resize((height, height), Image.LANCZOS)


# MARK: - スライド合成

def soft_blob_bg(canvas: Image.Image, accent, cx, cy) -> None:
    """背景にアクセント色の柔らかい円ぼかしを敷く。"""
    blob = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(blob)
    d.ellipse([cx - 700, cy - 700, cx + 700, cy + 700], fill=accent + (46,))
    canvas.alpha_composite(blob.filter(ImageFilter.GaussianBlur(180)))


def paste_phone(canvas: Image.Image, phone: Image.Image, cx: int,
                target_h: int = 1190) -> None:
    """影付きで端末を縦中央に置く。"""
    ratio = target_h / phone.height
    p = phone.resize((int(phone.width * ratio), target_h), Image.LANCZOS)
    px, py = cx - p.width // 2, (canvas.height - p.height) // 2 + 14
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + 14, py + 30, px + p.width + 14, py + p.height + 30],
        radius=130, fill=(60, 45, 35, 90))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(36)))
    canvas.alpha_composite(p, (px, py))


def draw_text_block(canvas, x, headline, sub, accent, weight=700, scale=1.0):
    d = ImageDraw.Draw(canvas)
    head_f = jp_font(round(150 * scale), weight)
    sub_f = jp_font(round(56 * scale), 420)
    lines = headline.split("\n")
    line_h = round(196 * scale)
    sub_h = round(86 * scale)
    sub_lines = sub.split("\n")
    total = len(lines) * line_h + round(70 * scale) + len(sub_lines) * sub_h
    y = (canvas.height - total) // 2 - 20
    for ln in lines:
        d.text((x, y), ln, font=head_f, fill=INK)
        y += line_h
    bar_y = y + round(26 * scale)
    d.rounded_rectangle([x + 6, bar_y, x + round(126 * scale), bar_y + 14],
                        radius=7, fill=accent)
    y += round(70 * scale)
    for ln in sub_lines:
        d.text((x + 6, y), ln, font=sub_f, fill=SUB_INK)
        y += sub_h
    return y


def wordmark(canvas, x, y, size=64):
    """アプリアイコン + ワードマーク文字。"""
    ch = icon_glyph(size)
    canvas.alpha_composite(ch, (x, y))
    d = ImageDraw.Draw(canvas)
    f = ImageFont.truetype(str(LATIN_SANS), int(size * 0.78))
    d.text((x + ch.width + 22, y + size * 0.16), WORDMARK, font=f, fill=INK)


def accent_dots(canvas, x, y):
    d = ImageDraw.Draw(canvas)
    for i, c in enumerate(ACCENTS.values()):
        cx = x + i * 56
        d.ellipse([cx, y, cx + 22, y + 22], fill=c)


def make_slide(out, spec, dev, out_path: Path):
    canvas_size = dev["canvas"]
    canvas = Image.new("RGBA", canvas_size, BG + (255,))
    material = MATERIAL / dev["material"] if dev["material"] else MATERIAL
    shot = Image.open(material / spec["shot"])
    scene_name = spec.get("scene")
    if scene_name:
        scene = footage_or(spec.get("footage"), SCENES[scene_name])
        keyed = key_out_green(shot, scene)
    else:
        keyed = shot.convert("RGB")
    phone_right = spec.get("phone_right", True)
    accent = ACCENTS[spec.get("accent", "evening")]
    phone_cx = dev["phone_cx"][0] if phone_right else dev["phone_cx"][1]
    text_x = dev["text_x"][0] if phone_right else dev["text_x"][1]
    soft_blob_bg(canvas, accent, phone_cx, dev["blob_cy"])
    paste_phone(canvas, phone_mockup(keyed, dev["screen_r"], dev["bezel"]),
                phone_cx, dev["target_h"])
    draw_text_block(canvas, text_x, spec["headline"], spec["sub"], accent,
                    scale=dev["scale"])
    if spec.get("show_wordmark"):
        wordmark(canvas, text_x + 6, dev["wordmark_y"])
    if spec.get("show_dots"):
        accent_dots(canvas, text_x + 6, dev["dots_y"])
    char_h = spec.get("icon_h", 0)
    if char_h:
        char_h = round(char_h * dev["scale"])
        ch = icon_glyph(char_h)
        cx = text_x + 6 if phone_right else canvas_size[0] - 260 - ch.width
        cy = canvas_size[1] - char_h - dev["char_bottom"]
        ground = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
        ImageDraw.Draw(ground).ellipse(
            [cx - 14, cy + char_h - 10, cx + ch.width + 14, cy + char_h + 26],
            fill=(60, 45, 35, 50))
        canvas.alpha_composite(ground.filter(ImageFilter.GaussianBlur(10)))
        canvas.alpha_composite(ch, (cx, cy))
    out_path.mkdir(parents=True, exist_ok=True)
    name = dev["prefix"] + out
    canvas.convert("RGB").save(out_path / name)
    print("wrote", out_path / name)


def main():
    ensure_noto()
    slides = json.loads((ROOT / "scripts/store_slides.json")
                        .read_text(encoding="utf-8"))["slides"]
    out_path = out_dir()
    for dev in DEVICES.values():
        # iPhone 専用アプリ。素材ディレクトリの無いデバイス（例 ipad13）は黙ってスキップ。
        material = MATERIAL / dev["material"] if dev["material"] else MATERIAL
        if not material.exists():
            print("skip device (no material dir):", material)
            continue
        for spec in slides:
            make_slide(spec["out"], spec, dev, out_path)


if __name__ == "__main__":
    main()
