# Building Video Wallpaper App Without Xcode

Yes! You can build and run this app without Xcode using the command-line tools.

## Quick Start

### 1. Build the App
```bash
cd /Users/varnith/VideoWallpaperApp
./build.sh
```

### 2. Create .app Bundle
```bash
./create_app_bundle.sh
```

### 3. Run the App
```bash
open build/VideoWallpaperApp.app
```

Or run directly:
```bash
./build/VideoWallpaperApp.app/Contents/MacOS/VideoWallpaperApp
```

## What These Scripts Do

### build.sh
- Compiles all Swift files using swiftc
- Links required frameworks (Cocoa, SwiftUI, AVFoundation, etc.)
- Creates an executable in the `build/` directory
- Uses ARM64 architecture for Apple Silicon Macs

### create_app_bundle.sh
- Creates a proper macOS .app bundle structure
- Copies the executable to the correct location
- Creates Info.plist with proper metadata
- Copies assets and entitlements
- Makes the app double-clickable from Finder

## Manual Build Commands

If you prefer to build manually:

```bash
# Compile all Swift files
swiftc \
    -o build/VideoWallpaperApp \
    VideoWallpaperApp/*.swift \
    -framework Cocoa \
    -framework SwiftUI \
    -framework AVFoundation \
    -framework ApplicationServices \
    -framework UserNotifications \
    -target arm64-apple-macosx14.0 \
    -O

# Run the executable
./build/VideoWallpaperApp
```

## Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9 or later (comes with Xcode Command Line Tools)
- Command Line Tools installed:
  ```bash
  xcode-select --install
  ```

## Project Structure

```
VideoWallpaperApp/
├── VideoWallpaperApp/          # Source files
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   ├── NetworkManager.swift
│   ├── WallpaperManager.swift
│   ├── DesktopWindowController.swift
│   ├── LockScreenManager.swift
│   ├── WallpaperHistoryView.swift
│   └── Assets.xcassets
├── build.sh                    # Build script
├── create_app_bundle.sh       # App bundle creator
├── Package.swift              # Swift Package Manager config
└── build/                      # Build output
    ├── VideoWallpaperApp       # Executable
    └── VideoWallpaperApp.app   # .app bundle
```

## Using Swift Package Manager

You can also use Swift Package Manager:

```bash
# Build using SPM
swift build

# Run using SPM
swift run
```

## Features Available Without Xcode

✅ **Desktop Video Wallpaper** - Full functionality
✅ **Network Manager** - Web scraping and downloads
✅ **Wallpaper Management** - History and downloads
✅ **Lock Screen Integration** - File management
✅ **Status Bar Integration** - System tray controls
✅ **Notifications** - User notifications

## Limitations Without Xcode

❌ **Screen Saver Plugin** - Requires Xcode to build .saver bundle
❌ **Interface Builder** - Manual UI code only (SwiftUI works fine)
❌ **Scheme Management** - Uses simple build scripts instead
❌ **Asset Catalog Editing** - Manual editing of assets

## Troubleshooting

### Build Fails
```bash
# Ensure Command Line Tools are installed
xcode-select --install

# Check Swift version
swift --version

# Verify all source files exist
ls VideoWallpaperApp/*.swift
```

### App Won't Launch
```bash
# Check executable permissions
chmod +x build/VideoWallpaperApp.app/Contents/MacOS/VideoWallpaperApp

# Run directly to see errors
./build/VideoWallpaperApp.app/Contents/MacOS/VideoWallpaperApp
```

### Permission Errors
The app may need accessibility permissions:
1. System Preferences > Security & Privacy > Privacy > Accessibility
2. Add VideoWallpaperApp to the list
3. Restart the app

## Advantages of Building Without Xcode

- **Faster** - No Xcode overhead
- **Simpler** - Direct command-line control
- **Scriptable** - Easy to automate builds
- **Lightweight** - Uses only Command Line Tools
- **Portable** - Can be built on any Mac with Swift

## Continuous Integration

These scripts make it easy to set up CI/CD:

```yaml
# Example GitHub Actions
- name: Build
  run: |
    ./build.sh
    ./create_app_bundle.sh
```

## Development Workflow

1. Edit Swift files in your preferred editor
2. Run `./build.sh` to compile
3. Run `./create_app_bundle.sh` to create .app
4. Test with `open build/VideoWallpaperApp.app`
5. Iterate without opening Xcode

## Performance

The command-line build is typically faster than Xcode for:
- Small to medium projects
- Iterative development
- Automated builds
- CI/CD pipelines

This approach gives you full control over the build process while avoiding Xcode's overhead!