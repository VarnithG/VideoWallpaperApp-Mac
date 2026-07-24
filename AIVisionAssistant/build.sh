#!/bin/bash

# Build the standalone AI Vision Assistant executable without Xcode.
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_NAME="AIVisionAssistant"
mkdir -p "$BUILD_DIR"

SOURCES=()
while IFS= read -r file; do
    SOURCES+=("$file")
done < <(find "$ROOT_DIR/AIVisionAssistant" -type f -name '*.swift' | sort)
swiftc \
    -o "$BUILD_DIR/$APP_NAME" \
    "${SOURCES[@]}" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework ScreenCaptureKit \
    -framework Carbon \
    -framework Security \
    -framework CoreGraphics \
    -framework UniformTypeIdentifiers \
    -framework Foundation \
    -target arm64-apple-macosx13.0 \
    -O

echo "Build successful: $BUILD_DIR/$APP_NAME"
