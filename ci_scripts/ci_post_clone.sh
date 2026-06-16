#!/bin/sh

# Xcode Cloud の post-clone フック（リポジトリ clone 直後・ビルド前に自動実行される）。
#
# なぜ必要か:
#   pbxproj は CURRENT_PROJECT_VERSION = 1 を Debug / Release 両コンフィグに
#   ハードコードしている（MARKETING_VERSION = 1.0）。このままだと Xcode Cloud で
#   何回ビルドしても書き出されるバイナリは毎回 1.0 (1) になり、2 回目以降の
#   App Store Connect アップロードが「ビルド番号が既存と重複」で弾かれる
#   （Xcode Cloud 上は "Preparing build for App Store Connect failed" と表示）。
#
#   そこで各ビルドで CFBundleVersion を Xcode Cloud のビルド番号（CI_BUILD_NUMBER、
#   単調増加）に揃え、アップロードのたびに一意かつ増加する番号になるようにする。
#
# 注意:
#   - VERSIONING_SYSTEM = apple-generic を設定していないため agvtool は使わず、
#     pbxproj の CURRENT_PROJECT_VERSION を直接置換する（現状の値はすべて整数リテラル）。
#   - MARKETING_VERSION（1.0）は人手で上げる運用のまま。ここでは触らない。
#   - MediaPipe の plist 修正は別フック（ci_pre_xcodebuild.sh）が担当する。

set -e

if [ -z "$CI_BUILD_NUMBER" ]; then
    echo "CI_BUILD_NUMBER が未設定です。Xcode Cloud 以外では何もしません。"
    exit 0
fi

PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/mensmakeupadvisor.xcodeproj/project.pbxproj"

echo "CFBundleVersion を CI_BUILD_NUMBER=$CI_BUILD_NUMBER に揃えます: $PBXPROJ"
/usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [0-9][0-9]*;/CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER};/g" "$PBXPROJ"

echo "置換後の CURRENT_PROJECT_VERSION:"
/usr/bin/grep -n "CURRENT_PROJECT_VERSION" "$PBXPROJ"
