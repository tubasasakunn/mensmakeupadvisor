#!/usr/bin/env python3
"""App Store Connect のメタデータ文字数チェック。

release/<version>/*.txt を走査し、各フィールドの文字数が
App Store Connect の上限以内かを検証する。

  使い方: python3 scripts/check_release_metadata.py [version]
          version 省略時は release/ 配下の全バージョンを検査

文字数は App Store Connect と同じく Unicode 1 文字 = 1 カウント
（日本語・英数字とも等価）。末尾の改行 1 つはファイル整形用とみなして除外する。
"""

import sys
from pathlib import Path

# App Store Connect の上限（最終確認 2026-06。仕様が変わったら更新する）
LIMITS = {
    "app_name.txt": 30,
    "subtitle.txt": 30,
    "promotional_text.txt": 170,
    "description.txt": 4000,
    "keywords.txt": 100,
    "whats_new.txt": 4000,
}


def check_version(version_dir: Path) -> bool:
    ok = True
    print(f"== {version_dir.name} ==")
    for filename, limit in LIMITS.items():
        path = version_dir / filename
        if not path.exists():
            print(f"  MISSING  {filename}")
            ok = False
            continue
        text = path.read_text(encoding="utf-8")
        if text.endswith("\n"):
            text = text[:-1]
        count = len(text)
        status = "OK " if count <= limit else "OVER"
        if count > limit:
            ok = False
        print(f"  {status}  {filename:<24} {count:>5} / {limit}")

        if filename == "keywords.txt":
            ok &= check_keywords(text)
    return ok


def check_keywords(text: str) -> bool:
    ok = True
    if "、" in text or "，" in text:
        print("         keywords: 区切りは半角カンマ ',' を使うこと")
        ok = False
    if " " in text or "　" in text:
        print("         keywords: 空白は入れないこと（カンマのみで区切る）")
        ok = False
    terms = [t for t in text.split(",") if t]
    dupes = {t for t in terms if terms.count(t) > 1}
    if dupes:
        print(f"         keywords: 重複あり {sorted(dupes)}")
        ok = False
    return ok


def main() -> int:
    root = Path(__file__).resolve().parent.parent / "release"
    if not root.is_dir():
        print(f"release/ が見つかりません: {root}")
        return 1
    if len(sys.argv) > 1:
        dirs = [root / sys.argv[1]]
    else:
        dirs = sorted(p for p in root.iterdir() if p.is_dir())
    if not dirs:
        print("release/ にバージョンディレクトリがありません")
        return 1
    all_ok = True
    for d in dirs:
        if not d.is_dir():
            print(f"バージョンディレクトリがありません: {d}")
            return 1
        all_ok &= check_version(d)
    print("PASS" if all_ok else "FAIL")
    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
