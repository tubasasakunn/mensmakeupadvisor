#!/usr/bin/env python3
"""release/<version>/ を fastlane deliver のレイアウトへ同期する。

App Store Connect への自動反映（.github/workflows/appstore-metadata.yml）の
前段。release/ のファイル名と deliver の期待名のマッピングはここが正本。

  使い方: python3 scripts/sync_fastlane_metadata.py [version]
          version 省略時は appstore.config.json の xcodeproj の MARKETING_VERSION

出力: fastlane/metadata/<locale>/*.txt と fastlane/screenshots/<locale>/*.png
GITHUB_OUTPUT が設定されていれば version=<version> を書き出す。
"""

import os
import re
import shutil
import sys
from pathlib import Path

from _config import get

ROOT = Path(__file__).resolve().parent.parent
LOCALE = get("appstore", "primary_locale", default="ja")  # 主ロケール

# release/<version>/ のファイル名 → deliver のメタデータ名（locale 配下）
MAPPING = {
    "app_name.txt": "name.txt",
    "subtitle.txt": "subtitle.txt",
    "promotional_text.txt": "promotional_text.txt",
    "description.txt": "description.txt",
    "keywords.txt": "keywords.txt",
    "whats_new.txt": "release_notes.txt",
    "support_url.txt": "support_url.txt",
    "marketing_url.txt": "marketing_url.txt",
    "privacy_url.txt": "privacy_url.txt",
}

# ロケール非依存のメタデータ（fastlane/metadata/ 直下）。無ければスキップ
NONLOCAL_MAPPING = {
    "primary_category.txt": "primary_category.txt",
    "secondary_category.txt": "secondary_category.txt",
    "copyright.txt": "copyright.txt",
}


def marketing_version() -> str:
    xcodeproj = get("app", "xcodeproj", default="App.xcodeproj")
    pbxproj = (ROOT / xcodeproj / "project.pbxproj").read_text()
    versions = set(re.findall(r"MARKETING_VERSION = ([^;]+);", pbxproj))
    if len(versions) != 1:
        sys.exit(f"MARKETING_VERSION が一意でない: {sorted(versions)}")
    return versions.pop()


def main() -> None:
    version = sys.argv[1] if len(sys.argv) > 1 else marketing_version()
    src = ROOT / "release" / version
    if not src.is_dir():
        sys.exit(f"release/{version}/ がありません（MARKETING_VERSION と一致が必要）")

    meta_dir = ROOT / "fastlane/metadata" / LOCALE
    shot_dir = ROOT / "fastlane/screenshots" / LOCALE
    for d in (meta_dir, shot_dir):
        shutil.rmtree(d, ignore_errors=True)
        d.mkdir(parents=True)

    for src_name, dst_name in MAPPING.items():
        path = src / src_name
        if not path.exists():
            sys.exit(f"{path} がありません")
        text = path.read_text(encoding="utf-8")
        if text.endswith("\n"):  # 末尾改行は整形用。ASC へは含めない
            text = text[:-1]
        (meta_dir / dst_name).write_text(text, encoding="utf-8")

    nonlocal_count = 0
    for src_name, dst_name in NONLOCAL_MAPPING.items():
        path = src / src_name
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8")
        if text.endswith("\n"):
            text = text[:-1]
        (meta_dir.parent / dst_name).write_text(text, encoding="utf-8")
        nonlocal_count += 1

    shots = sorted((src / "img").glob("*.png"))
    if not shots:
        sys.exit(f"release/{version}/img/ に .png がありません")
    for shot in shots:
        shutil.copy2(shot, shot_dir / shot.name)

    print(f"synced release/{version} -> fastlane/ ({len(MAPPING)} texts, "
          f"{nonlocal_count} app-info texts, {len(shots)} screenshots)")
    github_output = os.environ.get("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as fh:
            fh.write(f"version={version}\n")


if __name__ == "__main__":
    main()
