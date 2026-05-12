#!/bin/sh
# MediaPipeTasksVision.framework の Info.plist を修復するスクリプト。
#
# 問題: SwiftTasksVision が同梱する MediaPipeTasksVision.xcframework 内の
#       各 .framework/Info.plist が XCFramework 用 plist のまま誤配置されており、
#       App Store 提出時に以下エラーになる:
#         ITMS-90530 / ITMS-90360 / ITMS-90056 / ITMS-90057
#
# 対策: ビルド前に SPM チェックアウト内の Info.plist を正しい内容に書き換える。
#       DerivedData クリーン後も毎ビルドで自動修復されるように常時実行する。

set -eu

CORRECT_PLIST='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>MediaPipeTasksVision</string>
	<key>CFBundleIdentifier</key>
	<string>com.mediapipetasksvision</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>MediaPipeTasksVision</string>
	<key>CFBundlePackageType</key>
	<string>FMWK</string>
	<key>CFBundleShortVersionString</key>
	<string>0.10.21</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>MinimumOSVersion</key>
	<string>15.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
</dict>
</plist>'

patch_plist() {
  local plist="$1"
  if [ ! -f "$plist" ]; then
    echo "note: fix_mediapipe: not found, skipping: $plist"
    return 0
  fi
  # 既に正しい内容ならスキップ（CFBundleShortVersionString の有無で判定）
  if /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" > /dev/null 2>&1; then
    echo "note: fix_mediapipe: already correct: $plist"
    return 0
  fi
  chmod u+w "$plist"
  printf '%s\n' "$CORRECT_PLIST" > "$plist"
  echo "fix_mediapipe: patched $plist"
}

# ── 1. SPM チェックアウト内を修復（DerivedData クリーン後も次ビルドで自動修復）
# SYMROOT は常に .../DerivedData/<ID>/Build/... の形式なので、Build より前を取り出す
DERIVED_DATA_ROOT="${SYMROOT%%/Build/*}"
SPM_XCFW="$DERIVED_DATA_ROOT/SourcePackages/checkouts/SwiftTasksVision/Dependencies/MediaPipeTasksVision.xcframework"

if [ -d "$SPM_XCFW" ]; then
  patch_plist "$SPM_XCFW/ios-arm64/MediaPipeTasksVision.framework/Info.plist"
  patch_plist "$SPM_XCFW/ios-arm64_x86_64-simulator/MediaPipeTasksVision.framework/Info.plist"
else
  echo "note: fix_mediapipe: SPM checkout not found at $SPM_XCFW (will retry on next build)"
fi

# ── 2. ビルド済みバンドル内も修復（Archive / Install 時のベルト & サスペンダー）
for candidate in \
  "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MediaPipeTasksVision.framework" \
  "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/MediaPipeTasksVision.framework" \
  "${CODESIGNING_FOLDER_PATH}/Frameworks/MediaPipeTasksVision.framework" \
  "${DSTROOT:-}/Applications/${WRAPPER_NAME}/Frameworks/MediaPipeTasksVision.framework"
do
  if [ -d "$candidate" ]; then
    patch_plist "$candidate/Info.plist"

    # Info.plist 変更後に再署名（署名 ID がある場合のみ）
    SIGN_ID="${EXPANDED_CODE_SIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}"
    if [ -n "$SIGN_ID" ] && [ "$SIGN_ID" != "-" ]; then
      /usr/bin/codesign --force \
        --sign "$SIGN_ID" \
        --preserve-metadata=identifier,entitlements,flags \
        --timestamp=none \
        "$candidate" 2>/dev/null && echo "fix_mediapipe: re-signed $candidate" || true
    fi
  fi
done

exit 0
