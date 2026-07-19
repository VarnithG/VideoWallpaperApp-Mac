#!/bin/bash

# Build script for Video Wallpaper App without Xcode
# This compiles the Swift files and creates a basic executable

set -e

echo "Building Video Wallpaper App..."

# Build directory
BUILD_DIR="build"
APP_NAME="VideoWallpaperApp"
SOURCES="VideoWallpaperApp/*.swift"

# Create build directory
mkdir -p "$BUILD_DIR"

# Compile the Swift files
echo "Compiling Swift files..."
swiftc \
    -o "$BUILD_DIR/$APP_NAME" \
    VideoWallpaperApp/main.swift \
    VideoWallpaperApp/ContentView.swift \
    VideoWallpaperApp/NetworkManager.swift \
    VideoWallpaperApp/WallpaperManager.swift \
    VideoWallpaperApp/DesktopWindowController.swift \
    VideoWallpaperApp/LockScreenManager.swift \
    VideoWallpaperApp/WallpaperHistoryView.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -framework AVFoundation \
    -framework ApplicationServices \
    -framework UserNotifications \
    -target arm64-apple-macosx14.0 \
    -O

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "Executable created at: $BUILD_DIR/$APP_NAME"
    echo ""
    echo "To run the app:"
    echo "  ./$BUILD_DIR/$APP_NAME"
else
    echo "❌ Build failed"
    exit 1
fi