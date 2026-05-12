#!/bin/sh
# SwiftTasksVision (MediaPipeTasksVision.framework) は同梱 Info.plist が
# 壊れており、App Store 提出時に下記エラーになる:
#   ITMS-90530 / ITMS-90360 / ITMS-90057 / ITMS-90056
# (CFBundleShortVersionString / CFBundleVersion / MinimumOSVersion 欠落,
#  XCFramework 用 plist が誤って framework 内に置かれている)
#
# このスクリプトは Embed Frameworks 完了後に走り、Info.plist を完全に書き直して
# フレームワークを再署名する。途中失敗で Build Phase を落とさないよう全コマンドで
# || true を入れて続行する。

set -u

FRAMEWORK="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/MediaPipeTasksVision.framework"

# 通常の Embed 場所に無ければ、Archive の Embedded Binaries や PlugIns も確認する
if [ ! -d "$FRAMEWORK" ]; then
  for candidate in \
    "${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}/MediaPipeTasksVision.framework" \
    "${CODESIGNING_FOLDER_PATH}/Frameworks/MediaPipeTasksVision.framework" \
    "${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}/Frameworks/MediaPipeTasksVision.framework"
  do
    if [ -d "$candidate" ]; then
      FRAMEWORK="$candidate"
      break
    fi
  done
fi

if [ ! -d "$FRAMEWORK" ]; then
  echo "note: MediaPipeTasksVision.framework not yet embedded (will be fixed on a later build), skipping"
  exit 0
fi

PLIST="$FRAMEWORK/Info.plist"
echo "Patching $PLIST"

# Info.plist を 0 から書き直す (PlistBuddy より失敗しにくい)
cat > "$PLIST" <<'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
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
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>iPhoneOS</string>
	</array>
	<key>MinimumOSVersion</key>
	<string>15.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
	<key>UIRequiredDeviceCapabilities</key>
	<array>
		<string>arm64</string>
	</array>
</dict>
</plist>
PLIST_EOF

# 念のため XML として正当か検証 (失敗してもビルド止めない)
plutil -lint "$PLIST" || echo "warning: plutil -lint failed on $PLIST"

# Info.plist を改変したので再署名。CODE_SIGN_IDENTITY が空 (シミュレータ等) の
# ケースは skip。失敗時も Build を止めない。
SIGN_ID="${EXPANDED_CODE_SIGN_IDENTITY:-}"
if [ -z "$SIGN_ID" ]; then
  SIGN_ID="${CODE_SIGN_IDENTITY:-}"
fi
if [ -n "$SIGN_ID" ] && [ "$SIGN_ID" != "-" ]; then
  /usr/bin/codesign --force \
    --sign "$SIGN_ID" \
    --preserve-metadata=identifier,entitlements,flags \
    --timestamp=none \
    "$FRAMEWORK" || echo "warning: codesign failed for $FRAMEWORK"
  echo "Re-signed $FRAMEWORK with $SIGN_ID"
else
  echo "note: no code-sign identity set, skipping codesign"
fi

exit 0
