#!/bin/sh
# SwiftTasksVision (MediaPipeTasksVision.framework) は同梱 Info.plist が
# 壊れており、App Store 提出時に下記エラーになる:
#   ITMS-90530 / ITMS-90360 / ITMS-90057 / ITMS-90056
# (CFBundleShortVersionString / CFBundleVersion / MinimumOSVersion 欠落,
#  XCFramework 用 plist が誤って framework 内に置かれている)
#
# このスクリプトは Embed Frameworks 完了後に走り、Info.plist を正規化して
# フレームワークを再署名する。MediaPipeCommonGraphLibraries.framework 側は
# 既に正規 plist なので触らない。

set -eu

FRAMEWORK="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MediaPipeTasksVision.framework"
if [ ! -d "$FRAMEWORK" ]; then
  echo "MediaPipeTasksVision.framework not found at $FRAMEWORK, skipping"
  exit 0
fi

PLIST="$FRAMEWORK/Info.plist"
PB=/usr/libexec/PlistBuddy

# 1. XCFramework 専用キーを除去
$PB -c "Delete :AvailableLibraries" "$PLIST" 2>/dev/null || true
$PB -c "Delete :XCFrameworkFormatVersion" "$PLIST" 2>/dev/null || true

# 2. iOS Framework 必須キーを補完
add_or_set() {
  local key="$1"; local type="$2"; local val="$3"
  $PB -c "Set :$key $val" "$PLIST" 2>/dev/null \
    || $PB -c "Add :$key $type $val" "$PLIST"
}
add_or_set CFBundleDevelopmentRegion       string  en
add_or_set CFBundleExecutable              string  MediaPipeTasksVision
add_or_set CFBundleIdentifier              string  com.mediapipetasksvision
add_or_set CFBundleInfoDictionaryVersion   string  6.0
add_or_set CFBundleName                    string  MediaPipeTasksVision
add_or_set CFBundlePackageType             string  FMWK
add_or_set CFBundleShortVersionString      string  0.10.21
add_or_set CFBundleVersion                 string  1
add_or_set MinimumOSVersion                string  15.0

# CFBundleSupportedPlatforms (array)
$PB -c "Add :CFBundleSupportedPlatforms array" "$PLIST" 2>/dev/null || true
$PB -c "Delete :CFBundleSupportedPlatforms:0" "$PLIST" 2>/dev/null || true
$PB -c "Add :CFBundleSupportedPlatforms:0 string iPhoneOS" "$PLIST"

# UIRequiredDeviceCapabilities (arm64 only)
$PB -c "Add :UIRequiredDeviceCapabilities array" "$PLIST" 2>/dev/null || true
$PB -c "Delete :UIRequiredDeviceCapabilities:0" "$PLIST" 2>/dev/null || true
$PB -c "Add :UIRequiredDeviceCapabilities:0 string arm64" "$PLIST"

echo "Patched $PLIST"
$PB -c "Print" "$PLIST"

# 3. Info.plist を改変したので再署名
if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "${EXPANDED_CODE_SIGN_IDENTITY}" != "-" ]; then
  /usr/bin/codesign --force \
    --sign "${EXPANDED_CODE_SIGN_IDENTITY}" \
    --preserve-metadata=identifier,entitlements,flags \
    --timestamp=none \
    "$FRAMEWORK"
  echo "Re-signed $FRAMEWORK with ${EXPANDED_CODE_SIGN_IDENTITY}"
else
  echo "EXPANDED_CODE_SIGN_IDENTITY not set, skipping codesign"
fi
