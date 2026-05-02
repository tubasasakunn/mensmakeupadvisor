#!/bin/bash
set -e

SIMULATOR_ID="05CC021D-B8FC-4A26-B152-FF143ACA4FFB"  # iPhone 17 Pro (Booted)
BUNDLE_ID="com.tubasasakun.mensmakeupadvisor"
SCHEME="mensmakeupadvisor"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/mensmakeupadvisor_build"
OUTPUT_DIR="$PROJECT_DIR/screenshots"
SCREENS=("01_splash" "02_onboarding" "03_capture" "04_analyzing" "05_diagnosis" "06_tutorial" "07_studio" "08_archive")

mkdir -p "$OUTPUT_DIR"
mkdir -p "$BUILD_DIR"

echo "=== Building app for simulator ==="
xcodebuild build \
  -project "$PROJECT_DIR/mensmakeupadvisor.xcodeproj" \
  -scheme "$SCHEME" \
  -destination "id=$SIMULATOR_ID" \
  -configuration Debug \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" \
  -quiet 2>&1 | tail -5

echo "=== Installing app ==="
xcrun simctl install "$SIMULATOR_ID" "$BUILD_DIR/$SCHEME.app"

echo "=== Terminating existing instance ==="
xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE_ID" 2>/dev/null || true
sleep 0.5

echo "=== Launching with screenshot mode ==="
xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE_ID" --screenshot-mode --mock-mode

echo "=== Taking screenshots (8 screens × 3s) ==="
# Initial wait for app launch
sleep 1.5

for screen in "${SCREENS[@]}"; do
  echo "  Capturing: $screen"
  xcrun simctl io "$SIMULATOR_ID" screenshot "$OUTPUT_DIR/${screen}.png"
  sleep 3
done

echo ""
echo "=== Screenshots saved to: $OUTPUT_DIR ==="
ls -la "$OUTPUT_DIR"
