#!/bin/bash

# Create proper macOS .app bundle structure
# This makes the executable behave like a real macOS app

set -e

APP_NAME="VideoWallpaperApp"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Creating macOS .app bundle..."

# Remove existing app bundle if it exists
if [ -d "$APP_BUNDLE" ]; then
    echo "Removing existing app bundle..."
    rm -rf "$APP_BUNDLE"
fi

# Create directory structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy executable
echo "Copying executable..."
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"
chmod +x "$MACOS/$APP_NAME"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$CONTENTS/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VideoWallpaperApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.videowallpaper.app</string>
    <key>CFBundleName</key>
    <string>VideoWallpaperApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Copy assets if they exist
if [ -d "VideoWallpaperApp/Assets.xcassets" ]; then
    echo "Copying assets..."
    cp -r "VideoWallpaperApp/Assets.xcassets" "$RESOURCES/"
fi

# Copy entitlements if they exist
if [ -f "VideoWallpaperApp/VideoWallpaperApp.entitlements" ]; then
    echo "Copying entitlements..."
    cp "VideoWallpaperApp/VideoWallpaperApp.entitlements" "$CONTENTS/"
fi

echo "✅ .app bundle created successfully!"
echo "App bundle location: $APP_BUNDLE"
echo ""
echo "To run the app:"
echo "  open $APP_BUNDLE"
echo ""
echo "Or directly:"
echo "  $MACOS/$APP_NAME"