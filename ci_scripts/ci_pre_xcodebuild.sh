#!/bin/sh
# Xcode Cloud 用プレビルドスクリプト。
# xcodebuild が実行される前に走るため、フレームワーク embed + 署名より確実に先に実行される。
#
# MediaPipeTasksVision.xcframework 内の各 .framework/Info.plist が
# XCFramework 用 plist のまま誤配置されている問題を修正する。
#
# MinimumOSVersion は app の IPHONEOS_DEPLOYMENT_TARGET と揃える必要がある。
# Xcode は SwiftPM の static binary target を embed する際に dylib stub を生成し、
# その LC_BUILD_VERSION minos を app の deployment target に合わせる。
# plist の MinimumOSVersion が低いと「バイナリは X を要求しているのに plist は Y と
# 約束している」という不整合になり ITMS-90208 で reject される。

set -eu

# project.pbxproj から deployment target を読み取る
# Xcode Cloud では CI_PRIMARY_REPOSITORY_PATH がリポジトリルートを指す
REPO_ROOT="${CI_PRIMARY_REPOSITORY_PATH:-$PWD}"
PBX="$REPO_ROOT/mensmakeupadvisor.xcodeproj/project.pbxproj"
MIN_OS=""
if [ -f "$PBX" ]; then
  MIN_OS=$(grep -m 1 'IPHONEOS_DEPLOYMENT_TARGET' "$PBX" | awk -F'= ' '{print $2}' | tr -d '; ')
fi
MIN_OS="${MIN_OS:-26.0}"
echo "ci_pre_xcodebuild: using MinimumOSVersion=$MIN_OS"

CORRECT_PLIST="<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
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
	<string>${MIN_OS}</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
</dict>
</plist>"

patch_plist() {
  plist="$1"
  [ -f "$plist" ] || return 0
  current=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" 2>/dev/null || echo "")
  current_short=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || echo "")
  if [ "$current" = "$MIN_OS" ] && [ "$current_short" = "0.10.21" ]; then
    echo "ci_pre_xcodebuild: already correct: $plist"
    return 0
  fi
  chmod u+w "$plist"
  printf '%s\n' "$CORRECT_PLIST" > "$plist"
  echo "ci_pre_xcodebuild: patched (MinimumOSVersion=$MIN_OS): $plist"
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
