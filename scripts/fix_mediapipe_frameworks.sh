#!/bin/sh
# MediaPipeTasksVision.xcframework 同梱の問題を修復するスクリプト。
#
# 問題1: SwiftTasksVision が同梱する MediaPipeTasksVision.xcframework 内の
#        各 .framework/Info.plist が XCFramework 用 plist のまま誤配置されており、
#        ITMS-90530 / ITMS-90360 / ITMS-90056 / ITMS-90057 を引き起こす。
#
# 問題2: MediaPipeTasksVision のバイナリ本体は static archive (.a) だが、
#        SwiftPM/Xcode は embed 時に dylib stub を自動生成し
#        app/Frameworks/MediaPipeTasksVision.framework/MediaPipeTasksVision に置く。
#        この stub の LC_BUILD_VERSION minos は app の IPHONEOS_DEPLOYMENT_TARGET
#        (本プロジェクトでは 26.0) に揃えられる。
#        ところが Info.plist の MinimumOSVersion を 15.0 など低い値で書くと、
#        「バイナリは 26.0 を要求しているのに plist は 15.0 と約束している」
#        という不整合になり ITMS-90208
#        "does not support the minimum OS Version specified in the Info.plist"
#        で reject される。
#
# 対策: app の IPHONEOS_DEPLOYMENT_TARGET と同じ値で MinimumOSVersion を書く。
#   [1] ビルド前に SPM チェックアウト内の Info.plist を上記値で修復。
#       これにより embed 時に Xcode が同じ plist を埋め込むため、
#       バイナリ minos と一致する。
#   [2] 念のため embed 済みバンドル側も確認・修正し、変更した場合は再署名する。

set -eu

# app の deployment target に合わせて MinimumOSVersion を決める。
# 環境変数が未設定（手動実行など）の場合は xcodeproj から読み取る。
MIN_OS="${IPHONEOS_DEPLOYMENT_TARGET:-}"
if [ -z "$MIN_OS" ] && [ -n "${SRCROOT:-}" ]; then
  PBX="$SRCROOT/mensmakeupadvisor.xcodeproj/project.pbxproj"
  if [ -f "$PBX" ]; then
    MIN_OS=$(grep -m 1 'IPHONEOS_DEPLOYMENT_TARGET' "$PBX" | awk -F'= ' '{print $2}' | tr -d '; ')
  fi
fi
MIN_OS="${MIN_OS:-26.0}"

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

# 戻り値: 0=スキップ（既に正しい値）, 1=パッチ済み
patch_plist() {
  plist="$1"
  if [ ! -f "$plist" ]; then
    return 0
  fi
  current=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" 2>/dev/null || echo "")
  current_short=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist" 2>/dev/null || echo "")
  if [ "$current" = "$MIN_OS" ] && [ "$current_short" = "0.10.21" ]; then
    echo "note: fix_mediapipe: already correct (MinimumOSVersion=$MIN_OS): $plist"
    return 0
  fi
  chmod u+w "$plist"
  printf '%s\n' "$CORRECT_PLIST" > "$plist"
  echo "fix_mediapipe: patched (MinimumOSVersion=$MIN_OS): $plist"
  return 1
}

# ── 1. SPM チェックアウト内を修復（embed 前に直すため署名を壊さない）
# SYMROOT は .../DerivedData/<ID>/Build/... の形式なので Build より前を取り出す
DERIVED_DATA_ROOT="${SYMROOT%%/Build/*}"
SPM_XCFW="$DERIVED_DATA_ROOT/SourcePackages/checkouts/SwiftTasksVision/Dependencies/MediaPipeTasksVision.xcframework"

if [ -d "$SPM_XCFW" ]; then
  patch_plist "$SPM_XCFW/ios-arm64/MediaPipeTasksVision.framework/Info.plist"             || true
  patch_plist "$SPM_XCFW/ios-arm64_x86_64-simulator/MediaPipeTasksVision.framework/Info.plist" || true
else
  echo "note: fix_mediapipe: SPM checkout not found at $SPM_XCFW"
fi

# ── 2. embed 済みバンドル内も確認（[1] が成功していれば "already correct" で素通り）
#       実際にパッチした場合のみ再署名。再署名失敗はビルドエラーにする。
SIGN_ID="${EXPANDED_CODE_SIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}"

for candidate in \
  "${BUILT_PRODUCTS_DIR:-}/${FRAMEWORKS_FOLDER_PATH:-}/MediaPipeTasksVision.framework" \
  "${TARGET_BUILD_DIR:-}/${FRAMEWORKS_FOLDER_PATH:-}/MediaPipeTasksVision.framework" \
  "${CODESIGNING_FOLDER_PATH:-}/Frameworks/MediaPipeTasksVision.framework" \
  "${DSTROOT:-}/Applications/${WRAPPER_NAME:-}/Frameworks/MediaPipeTasksVision.framework"
do
  [ -d "$candidate" ] || continue

  # patch_plist の戻り値で「実際に書き換えたか」を判定
  if patch_plist "$candidate/Info.plist"; then
    # 戻り値 0 = 変更なし → 署名を触らない
    :
  else
    # 戻り値 1 = plist を書き換えた → 必ず再署名（失敗したらビルドエラー）
    if [ -n "$SIGN_ID" ] && [ "$SIGN_ID" != "-" ]; then
      echo "fix_mediapipe: re-signing $candidate"
      /usr/bin/codesign --force --sign "$SIGN_ID" --timestamp=none "$candidate" \
        || { echo "error: fix_mediapipe: codesign failed for $candidate" >&2; exit 1; }
      echo "fix_mediapipe: re-signed $candidate"
    else
      echo "note: fix_mediapipe: no signing identity — skipping re-sign of $candidate"
    fi
  fi
done

exit 0
