#!/usr/bin/env python3
"""SNS 投稿カルーセルの描画エンジン（ブランド共通）。

material/ のスクリーンショット（動画・画像領域は #00FF00 クロマキー）と
material/footage/ の日常フッテージを使い、TikTok（1080x1920 / 9:16）と
Lemon8（1080x1440 / 3:4）のカルーセル画像を合成する。

ブランドトークン（色・ワードマーク・フォント）は ../appstore.config.json から読む。
依存: Pillow, numpy
"""

import json
import re
import subprocess
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
MATERIAL = ROOT / "material"
FOOTAGE = MATERIAL / "footage"
SVG_DIR = ROOT / "post/assets/svg"

# MARK: - 設定（appstore.config.json）

_CFG = json.loads((ROOT / "appstore.config.json").read_text(encoding="utf-8"))
_brand = _CFG.get("brand", {})
_fonts = _CFG.get("fonts", {})


def _rgb(key, default):
    return tuple(_brand.get(key, default))


BG = _rgb("bg", [247, 244, 240])       # オフホワイト
INK = _rgb("ink", [42, 37, 32])        # 見出し
SUB_INK = _rgb("sub_ink", [111, 103, 96])
CARD = _rgb("card", [255, 255, 255])
ACCENTS = {k: tuple(v) for k, v in _brand.get("accents", {
    "morning": [232, 168, 124], "forenoon": [242, 201, 76],
    "afternoon": [168, 197, 160], "evening": [224, 123, 84],
    "night": [155, 114, 207], "midnight": [91, 127, 166],
}).items()}
ICON_COLOR = _rgb("icon_color", [197, 111, 82])
WORDMARK = _brand.get("wordmark", _CFG.get("app", {}).get("name", "App"))

HAIR = INK   # ヘアライン罫（INK と同色、α で薄く）

# 見出し用日本語フォント（OFL の Noto を /tmp へ取得）
SANS = Path("/tmp/NotoSansJP.ttf")
SERIF = Path("/tmp/NotoSerifJP.ttf")
SANS_URL = _fonts.get("jp_sans_url", "https://raw.githubusercontent.com/google/"
                      "fonts/main/ofl/notosansjp/NotoSansJP%5Bwght%5D.ttf")
SERIF_URL = _fonts.get("jp_serif_url", "https://raw.githubusercontent.com/google/"
                       "fonts/main/ofl/notoserifjp/NotoSerifJP%5Bwght%5D.ttf")

# 英字ロゴ・ラベル用（アプリ同梱 ttf があれば使う。無ければ Noto Sans で代用）
_latin_sans = _fonts.get("latin_sans_ttf", "")
_latin_mono = _fonts.get("latin_mono_ttf", "")
DM_SANS = (ROOT / _latin_sans) if _latin_sans else SANS
DM_MONO = {w: ((ROOT / _latin_mono) if _latin_mono else SANS)
           for w in ("light", "regular", "medium")}


def ensure_fonts():
    """見出し用 Noto（Sans/Serif）を /tmp へ取得する。冪等。"""
    for path, url in ((SANS, SANS_URL), (SERIF, SERIF_URL)):
        if not path.exists():
            subprocess.run(["curl", "-sL", "--max-time", "60", "-o", str(path), url],
                           check=True)


_font_cache = {}


def font(size, weight=600, serif=False):
    key = (size, weight, serif)
    if key in _font_cache:
        return _font_cache[key]
    f = ImageFont.truetype(str(SERIF if serif else SANS), size)
    try:
        f.set_variation_by_axes([weight])
    except OSError:
        pass
    _font_cache[key] = f
    return f


def serif_font(size, weight=600):
    """感情系の見出し・キャプション用（Noto Serif JP）。"""
    return font(size, weight, serif=True)


def dm_font(size):
    key = ("dm", size)
    if key not in _font_cache:
        try:
            _font_cache[key] = ImageFont.truetype(str(DM_SANS), size)
        except OSError:
            _font_cache[key] = font(size, 600)
    return _font_cache[key]


def mono_font(size, weight="medium"):
    """ラベル・番号・日付用。英字モノ ttf が無ければ Noto で代用。"""
    key = ("mono", size, weight)
    if key not in _font_cache:
        try:
            _font_cache[key] = ImageFont.truetype(str(DM_MONO[weight]), size)
        except OSError:
            _font_cache[key] = font(size, 500)
    return _font_cache[key]


# MARK: - エディトリアル部品（トラッキング / ヘアライン / グレイン / 枠ティック）

def tracked_width(draw, text, f, tracking):
    return sum(draw.textlength(c, font=f) for c in text) + tracking * max(len(text) - 1, 0)


def draw_tracked(draw, text, f, fill, x, y, tracking=0, anchor="l"):
    """字間（tracking）付きでテキストを描く。ラベルの“編集感”の要。"""
    if anchor != "l":
        w = tracked_width(draw, text, f, tracking)
        x = x - w if anchor == "r" else x - w / 2
    for c in text:
        draw.text((x, y), c, font=f, fill=fill)
        x += draw.textlength(c, font=f) + tracking
    return x


def hairline(canvas, x0, y, x1, color=HAIR, alpha=46, width=2):
    """クリスプな水平ヘアライン罫。"""
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).line([(x0, y), (x1, y)], fill=color + (alpha,), width=width)
    canvas.alpha_composite(layer)


def grain(canvas, seed=0, amount=15):
    """フィルム粒状感。フラットなグラデを脱して暖色グレードの世界観に揃える。"""
    rng = np.random.default_rng(seed)
    w, h = canvas.size
    n = rng.integers(0, 2, size=(h // 2, w // 2), dtype=np.uint8) * 255
    noise = Image.fromarray(n, "L").resize((w, h), Image.NEAREST)
    layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    layer.putalpha(noise.point(lambda v: amount if v else 0))
    canvas.alpha_composite(layer)


def _ss_layer(size, scale=4):
    return Image.new("RGBA", (size[0] * scale, size[1] * scale), (0, 0, 0, 0)), scale


def frame_ticks(canvas, color, alpha=150, margin=64, length=46, width=4, corners="all"):
    """フィルムフレームの四隅 L 字ティック（ベクター・SS でクリスプに）。"""
    layer, ss = _ss_layer(canvas.size)
    d = ImageDraw.Draw(layer)
    W, H = canvas.size
    m, L, wd = margin * ss, length * ss, width * ss
    pts = {"tl": (m, m, 1, 1), "tr": (W * ss - m, m, -1, 1),
           "bl": (m, H * ss - m, 1, -1), "br": (W * ss - m, H * ss - m, -1, -1)}
    use = pts.keys() if corners == "all" else corners
    for k in use:
        x, y, sx, sy = pts[k]
        d.line([(x, y), (x + sx * L, y)], fill=color + (alpha,), width=wd)
        d.line([(x, y), (x, y + sy * L)], fill=color + (alpha,), width=wd)
    canvas.alpha_composite(layer.resize(canvas.size, Image.LANCZOS))


def tick_label(canvas, text, x, y, color, accent, tracking=4, size=30, rule=34):
    """先頭に短いアクセント罫を付けたラベル「── ラベル」。日本語可（サンス＋字間）。"""
    d = ImageDraw.Draw(canvas)
    cy = y + size * 0.60
    d.line([(x, cy), (x + rule, cy)], fill=accent, width=3)
    f = font(size, 600)
    draw_tracked(d, text, f, color, x + rule + size * 0.5, y, tracking)
    return x + rule + size * 0.5


def arrow(canvas, x, y, length, color, width=3):
    """右向きのベクター矢印。"""
    layer, ss = _ss_layer(canvas.size)
    d = ImageDraw.Draw(layer)
    x0, y0 = x * ss, y * ss
    L, wd, hd = length * ss, width * ss, length * ss * 0.42
    d.line([(x0, y0), (x0 + L, y0)], fill=color, width=wd)
    d.line([(x0 + L - hd, y0 - hd), (x0 + L, y0)], fill=color, width=wd)
    d.line([(x0 + L - hd, y0 + hd), (x0 + L, y0)], fill=color, width=wd)
    canvas.alpha_composite(layer.resize(canvas.size, Image.LANCZOS))
    return x + length


# MARK: - SVG レンダラ（依存ゼロ・スーパーサンプリング）
# 外部ラスタライザ（cairosvg/rsvg）を入れずに post/assets/svg/*.svg を描画する。
# 対応: <path d=…(M/L/H/V/C/Q/Z, 絶対・相対)> / <line> / <circle> / <polyline|polygon> / <rect>。
# 単色モチーフ専用（fill/stroke の色は描画時に上書き）。transform 非対応なのでフラットに書く。

def _path_subpaths(d):
    toks = re.findall(r"[MmLlHhVvCcQqZz]|-?\d*\.?\d+(?:e-?\d+)?", d)
    i, cmd = 0, None
    pos, start = [0.0, 0.0], [0.0, 0.0]
    subs, cur = [], []

    def n():
        nonlocal i
        v = float(toks[i]); i += 1
        return v

    while i < len(toks):
        if re.match(r"[A-Za-z]", toks[i]):
            cmd = toks[i]; i += 1
        if cmd in ("M", "m"):
            x, y = n(), n()
            if cmd == "m":
                x += pos[0]; y += pos[1]
            if cur:
                subs.append((cur, False)); cur = []
            pos, start, cur = [x, y], [x, y], [(x, y)]
            cmd = "l" if cmd == "m" else "L"
        elif cmd in ("L", "l"):
            x, y = n(), n()
            if cmd == "l":
                x += pos[0]; y += pos[1]
            pos = [x, y]; cur.append((x, y))
        elif cmd in ("H", "h"):
            x = n() + (pos[0] if cmd == "h" else 0); pos = [x, pos[1]]; cur.append((x, pos[1]))
        elif cmd in ("V", "v"):
            y = n() + (pos[1] if cmd == "v" else 0); pos = [pos[0], y]; cur.append((pos[0], y))
        elif cmd in ("C", "c"):
            c = [n() for _ in range(6)]
            if cmd == "c":
                c = [c[k] + pos[k % 2] for k in range(6)]
            p0 = tuple(pos)
            for k in range(1, 19):
                t = k / 18; m = 1 - t
                cur.append((m**3 * p0[0] + 3 * m * m * t * c[0] + 3 * m * t * t * c[2] + t**3 * c[4],
                            m**3 * p0[1] + 3 * m * m * t * c[1] + 3 * m * t * t * c[3] + t**3 * c[5]))
            pos = [c[4], c[5]]
        elif cmd in ("Q", "q"):
            c = [n() for _ in range(4)]
            if cmd == "q":
                c = [c[k] + pos[k % 2] for k in range(4)]
            p0 = tuple(pos)
            for k in range(1, 19):
                t = k / 18; m = 1 - t
                cur.append((m * m * p0[0] + 2 * m * t * c[0] + t * t * c[2],
                            m * m * p0[1] + 2 * m * t * c[1] + t * t * c[3]))
            pos = [c[2], c[3]]
        elif cmd in ("Z", "z"):
            cur.append(tuple(start)); subs.append((cur, True)); cur = []
            pos = list(start)
        else:
            i += 1
    if cur:
        subs.append((cur, False))
    return subs


def _stroke_poly(d, pts, col, w):
    w = max(1, int(round(w)))
    if len(pts) >= 2:
        d.line(pts, fill=col, width=w, joint="curve")
    r = w / 2.0
    for x, y in pts:
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)


_SVG_EL = re.compile(r"<(path|line|circle|polyline|polygon|rect)\b([^>]*?)/?>", re.S)
_SVG_ATTR = re.compile(r'([\w:-]+)\s*=\s*"([^"]*)"')


def svg_image(name, color, height, ss=4):
    """SVG を単色でラスタライズして RGBA を返す。height は出力の縦px。
    pyexpat 非依存で、フラットな SVG を正規表現で読む。"""
    text = (SVG_DIR / (name if name.endswith(".svg") else name + ".svg")).read_text()
    m = re.search(r'viewBox\s*=\s*"([^"]+)"', text)
    if m:
        x0, y0, vw, vh = [float(v) for v in m.group(1).replace(",", " ").split()]
    else:
        x0 = y0 = 0.0
        vw = vh = 100.0
    sc = height * ss / vh
    img = Image.new("RGBA", (max(1, round(vw * sc)), max(1, round(vh * sc))), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    col = color if len(color) == 4 else color + (255,)

    def T(px, py):
        return ((px - x0) * sc, (py - y0) * sc)

    for tag, attrs in _SVG_EL.findall(text):
        a = dict(_SVG_ATTR.findall(attrs))
        fill = a.get("fill", "black")
        stroke = a.get("stroke", "none")
        sw = float(a.get("stroke-width", 2)) * sc
        if tag == "path":
            for pts, _closed in _path_subpaths(a.get("d", "")):
                P = [T(*p) for p in pts]
                if fill != "none":
                    d.polygon(P, fill=col)
                if stroke != "none" or fill == "none":
                    _stroke_poly(d, P, col, sw if sw else 2 * ss)
        elif tag == "circle":
            c = T(float(a.get("cx", 0)), float(a.get("cy", 0))); r = float(a.get("r", 0)) * sc
            if fill != "none":
                d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=col)
            else:
                d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], outline=col, width=int(sw))
        elif tag == "line":
            _stroke_poly(d, [T(float(a["x1"]), float(a["y1"])),
                             T(float(a["x2"]), float(a["y2"]))], col, sw)
        elif tag in ("polyline", "polygon"):
            v = [float(t) for t in a.get("points", "").replace(",", " ").split()]
            P = [T(v[k], v[k + 1]) for k in range(0, len(v) - 1, 2)]
            if tag == "polygon" and fill != "none":
                d.polygon(P, fill=col)
            else:
                _stroke_poly(d, P, col, sw)
        elif tag == "rect":
            x, y = T(float(a.get("x", 0)), float(a.get("y", 0)))
            w, h = float(a.get("width", 0)) * sc, float(a.get("height", 0)) * sc
            rr = float(a.get("rx", 0)) * sc
            box = [x, y, x + w, y + h]
            if fill != "none":
                d.rounded_rectangle(box, radius=rr, fill=col)
            else:
                d.rounded_rectangle(box, radius=rr, outline=col, width=int(sw))
    return img.resize((max(1, img.width // ss), max(1, img.height // ss)), Image.LANCZOS)


def paste_svg(canvas, name, x, y, height, color, anchor="l", alpha=255):
    """SVG モチーフを canvas に合成。anchor: l=左基準 / c=中心 / r=右基準。"""
    im = svg_image(name, color, height)
    if alpha < 255:
        a = im.getchannel("A").point(lambda v: v * alpha // 255)
        im.putalpha(a)
    if anchor == "c":
        x -= im.width // 2
    elif anchor == "r":
        x -= im.width
    canvas.alpha_composite(im, (round(x), round(y)))
    return im.width


def index_tag(canvas, idx, total, x, y, color, anchor="r", size=30):
    """「01 / 07」モノのページインデックス。"""
    d = ImageDraw.Draw(canvas)
    txt = f"{idx:02d} / {total:02d}"
    f = mono_font(size, "regular")
    draw_tracked(d, txt, f, color, x, y, 3, anchor=anchor)


def bottom_scrim(w, h, start=0.42, top_a=0, bot_a=205):
    """下方向に強まる黒スクリム（文字を載せる帯）。"""
    col = np.zeros(h, np.uint8)
    s0 = int(h * start)
    col[s0:] = np.linspace(top_a, bot_a, h - s0).astype(np.uint8)
    a = np.repeat(col[:, None], w, axis=1)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., 3] = a
    return Image.fromarray(rgba, "RGBA")


# MARK: - 画像ユーティリティ

def cover_crop(img, w, h):
    """アスペクトフィルで中央クロップして (w, h) に収める。"""
    img = img.convert("RGB")
    iw, ih = img.size
    scale = max(w / iw, h / ih)
    nw, nh = round(iw * scale), round(ih * scale)
    img = img.resize((nw, nh), Image.LANCZOS)
    x, y = (nw - w) // 2, (nh - h) // 2
    return img.crop((x, y, x + w, y + h))


def vgrad_alpha(w, h, top_a, bot_a):
    """上 top_a → 下 bot_a の黒の縦グラデーション（RGBA）。"""
    col = np.linspace(top_a, bot_a, h).astype(np.uint8)
    a = np.repeat(col[:, None], w, axis=1)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., 3] = a
    return Image.fromarray(rgba, "RGBA")


def footage_scene(path):
    """key_out_green 用に、フッテージを bbox サイズへ cover-crop する関数を返す。"""
    src = Image.open(path)
    return lambda size: cover_crop(src, size[0], size[1])


def key_out_green(shot, scene_for_bbox):
    """#00FF00 領域を検出し、その bbox に合わせたシーンで置き換える。"""
    rgb = np.asarray(shot.convert("RGB")).astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    strength = g - np.maximum(r, b)
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


# MARK: - アプリアイコングリフ / ワードマーク
# 元アプリのマスコット／ロゴに差し替える前提のプレースホルダ（角丸スクエア＋頭文字）。

def icon_glyph(height, body=ICON_COLOR):
    ss = 4
    size = height * ss
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, size, size], radius=int(size * 0.22), fill=body + (255,))
    letter = (WORDMARK[:1] or "A").upper()
    f = dm_font(int(size * 0.62))
    bbox = d.textbbox((0, 0), letter, font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text(((size - tw) / 2 - bbox[0], (size - th) / 2 - bbox[1]), letter,
           font=f, fill=(255, 255, 255, 235))
    return img.resize((height, height), Image.LANCZOS)


def wordmark(canvas, cx, y, size, ink=INK, anchor="c"):
    """アイコングリフ + ワードマーク文字。anchor: c=中心 / l=左基準 / r=右基準。"""
    ch = icon_glyph(size)
    f = dm_font(int(size * 0.74))
    d = ImageDraw.Draw(canvas)
    tw = d.textlength(WORDMARK, font=f)
    gap = int(size * 0.30)
    total = ch.width + gap + tw
    if anchor == "l":
        x = int(cx)
    elif anchor == "r":
        x = int(cx - total)
    else:
        x = int(cx - total / 2)
    canvas.alpha_composite(ch, (x, y))
    d.text((x + ch.width + gap, y + size * 0.18), WORDMARK, font=f, fill=ink)
    return total


def accent_dots(canvas, cx, y, r=11, gap=46):
    d = ImageDraw.Draw(canvas)
    cols = list(ACCENTS.values())
    total = (len(cols) - 1) * gap
    x0 = cx - total / 2
    for i, c in enumerate(cols):
        x = x0 + i * gap
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)


# MARK: - テキストブロック

def draw_lines(draw, lines, f, fill, cx, top, leading, align="center", stroke=0, stroke_fill=None):
    """複数行を中央/左寄せで描き、描画後の y を返す。"""
    y = top
    for ln in lines:
        w = draw.textlength(ln, font=f)
        if align == "center":
            x = cx - w / 2
        elif align == "left":
            x = cx
        else:
            x = cx - w
        draw.text((x, y), ln, font=f, fill=fill, stroke_width=stroke,
                  stroke_fill=stroke_fill)
        y += leading
    return y


def text_height(lines, leading):
    return len(lines) * leading


def rounded_plate(canvas, box, radius, fill):
    plate = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(plate).rounded_rectangle(box, radius=radius, fill=fill)
    canvas.alpha_composite(plate)


def soft_blob(canvas, accent, cx, cy, r=620, alpha=52):
    blob = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(blob).ellipse([cx - r, cy - r, cx + r, cy + r], fill=accent + (alpha,))
    canvas.alpha_composite(blob.filter(ImageFilter.GaussianBlur(150)))


# MARK: - 端末モックアップ

def phone_mockup(shot, screen_r=150, bezel=26):
    sw, sh = shot.size
    pad = 14
    body_w, body_h = sw + bezel * 2, sh + bezel * 2
    img = Image.new("RGBA", (body_w + pad * 2, body_h + pad * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([pad, pad, pad + body_w, pad + body_h],
                        radius=screen_r + bezel, fill=(23, 23, 26, 255))
    d.rounded_rectangle([pad + 5, pad + 5, pad + body_w - 5, pad + body_h - 5],
                        radius=screen_r + bezel - 5, outline=(72, 70, 68, 255), width=3)
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw, sh], radius=screen_r, fill=255)
    img.paste(shot.convert("RGB"), (pad + bezel, pad + bezel), mask)
    return img


def paste_phone_shadow(canvas, phone, cx, top, target_h):
    ratio = target_h / phone.height
    p = phone.resize((round(phone.width * ratio), target_h), Image.LANCZOS)
    px, py = round(cx - p.width / 2), top
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [px + 10, py + 26, px + p.width + 10, py + p.height + 26],
        radius=120, fill=(60, 45, 35, 80))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(34)))
    canvas.alpha_composite(p, (px, py))
    return p.width


def page_badge(canvas, idx, total, cx, y, on_dark=False):
    d = ImageDraw.Draw(canvas)
    f = dm_font(30)
    txt = f"{idx} / {total}"
    w = d.textlength(txt, font=f)
    pad = 22
    box = [cx - w / 2 - pad, y, cx + w / 2 + pad, y + 50]
    fill = (255, 255, 255, 46) if on_dark else (42, 37, 32, 16)
    rounded_plate(canvas, box, 25, fill)
    d.text((cx - w / 2, y + 9), txt, font=f, fill=(255, 255, 255) if on_dark else SUB_INK)
