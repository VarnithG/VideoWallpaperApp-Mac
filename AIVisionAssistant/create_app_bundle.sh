#!/bin/bash

# Assemble and ad-hoc sign the standalone macOS application bundle.
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="AIVisionAssistant"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"

if [ ! -x "$BUILD_DIR/$APP_NAME" ]; then
    echo "Missing executable. Run ./build.sh first." >&2
    exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS"
cp "$BUILD_DIR/$APP_NAME" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"
cp "$ROOT_DIR/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT_DIR/AIVisionAssistant.entitlements" "$CONTENTS/AIVisionAssistant.entitlements"
codesign --force --deep --sign - \
    --entitlements "$ROOT_DIR/AIVisionAssistant.entitlements" \
    "$APP_BUNDLE"

echo "Application bundle created: $APP_BUNDLE"
