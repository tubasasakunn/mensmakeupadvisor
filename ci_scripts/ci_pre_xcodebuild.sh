#!/bin/sh
# Xcode Cloud 用プレビルドスクリプト。
# xcodebuild が実行される前に走るため、フレームワーク embed + 署名より確実に先に実行される。
#
# MediaPipeTasksVision.xcframework 内の各 .framework/Info.plist が
# XCFramework 用 plist のまま誤配置されている問題を修正する。

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
  [ -f "$plist" ] || return 0
  if /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" > /dev/null 2>&1; then
    echo "ci_pre_xcodebuild: already correct: $plist"
    return 0
  fi
  chmod u+w "$plist"
  printf '%s\n' "$CORRECT_PLIST" > "$plist"
  echo "ci_pre_xcodebuild: patched $plist"
}

# Xcode Cloud では CI_DERIVED_DATA_PATH が設定されている
# ローカル実行時は SYMROOT から DerivedData ルートを推定
if [ -n "${CI_DERIVED_DATA_PATH:-}" ]; then
  DERIVED_DATA_ROOT="$CI_DERIVED_DATA_PATH"
elif [ -n "${SYMROOT:-}" ] && echo "$SYMROOT" | grep -q '/Build/'; then
  DERIVED_DATA_ROOT="${SYMROOT%%/Build/*}"
else
  echo "ci_pre_xcodebuild: cannot determine DerivedData root, skipping"
  exit 0
fi

SPM_XCFW="$DERIVED_DATA_ROOT/SourcePackages/checkouts/SwiftTasksVision/Dependencies/MediaPipeTasksVision.xcframework"

if [ ! -d "$SPM_XCFW" ]; then
  echo "ci_pre_xcodebuild: SPM checkout not found at $SPM_XCFW, skipping"
  exit 0
fi

patch_plist "$SPM_XCFW/ios-arm64/MediaPipeTasksVision.framework/Info.plist"
patch_plist "$SPM_XCFW/ios-arm64_x86_64-simulator/MediaPipeTasksVision.framework/Info.plist"
