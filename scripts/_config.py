#!/usr/bin/env python3
"""appstore.config.json を読む共通ローダー。

scripts/ 配下の各スクリプトと post/ のエンジンが、アプリ固有値
（アプリ名・bundle id・xcodeproj 名・ブランドカラー等）をここから取る。
新しいアプリにコピーしたら appstore.config.json だけ書き換えればよい。
"""

import json
from functools import lru_cache
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


@lru_cache(maxsize=1)
def config() -> dict:
    path = ROOT / "appstore.config.json"
    if not path.exists():
        raise SystemExit(
            f"appstore.config.json がありません: {path}\n"
            "swift-base をコピーしたら、まずこのファイルの値を全部置き換える。"
        )
    return json.loads(path.read_text(encoding="utf-8"))


def get(*keys, default=None):
    """ネストしたキーを安全に引く。get('app', 'bundle_id') のように使う。"""
    node = config()
    for key in keys:
        if not isinstance(node, dict) or key not in node:
            return default
        node = node[key]
    return node
