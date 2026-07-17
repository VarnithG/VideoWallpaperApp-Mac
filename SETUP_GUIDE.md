# Setup Guide for Video Wallpaper App

## Current Status

✅ **Git Repository**: Initialized and committed locally
✅ **Project Structure**: Complete with all Swift files
✅ **Dependencies**: SwiftSoup package configured
⚠️ **GitHub**: Manual setup required (GitHub CLI not installed)
⚠️ **Build**: Requires Xcode installation

## Next Steps

### 1. Create GitHub Repository

Since GitHub CLI is not installed, you'll need to create the repository manually:

1. Go to [github.com](https://github.com) and sign in
2. Click the "+" button and select "New repository"
3. Name it: `VideoWallpaperApp`
4. Description: "macOS app for video wallpapers, screensavers, and lock screen backgrounds"
5. Choose "Public" or "Private" as preferred
6. **Do not** initialize with README (we already have one)
7. Click "Create repository"

Then push your local repository:

```bash
cd /Users/varnith/VideoWallpaperApp
git remote add origin https://github.com/YOUR_USERNAME/VideoWallpaperApp.git
git branch -M main
git push -u origin main
```

### 2. Install Xcode

To build and run the app, you need Xcode:

1. Open the App Store
2. Search for "Xcode"
3. Download and install Xcode (requires ~10GB)
4. After installation, open Xcode and accept the license agreement
5. Install additional components when prompted

### 3. Open and Build Project

1. Navigate to the project directory:
   ```bash
   cd /Users/varnith/VideoWallpaperApp
   ```

2. Open the project in Xcode:
   ```bash
   open VideoWallpaperApp.xcodeproj
   ```

3. Add SwiftSoup dependency:
   - In Xcode, go to File > Add Package Dependencies
   - Enter: `https://github.com/scinfu/SwiftSoup.git`
   - Select version 2.6.0 or later
   - Click "Add Package"

4. Build the project:
   - Press `⌘ + B` to build
   - Select "VideoWallpaperApp" scheme
   - Press `⌘ + R` to run

### 4. Configure Permissions

When you first run the app, you'll need to grant permissions:

1. **Accessibility Permission** (for desktop wallpaper):
   - System Preferences > Security & Privacy > Privacy > Accessibility
   - Enable "Video Wallpaper"

2. **Full Disk Access** (for lock screen, optional):
   - System Preferences > Security & Privacy > Privacy > Full Disk Access
   - Enable "Video Wallpaper"

### 5. Install Screen Saver

After building the app:

1. Build the "VideoWallpaperScreenSaver" target
2. Copy the resulting `.saver` bundle to:
   `~/Library/Screen Savers/`
3. Open System Preferences > Desktop & Screen Saver
4. Select "Video Wallpaper Screen Saver"

## Project Structure Overview

```
VideoWallpaperApp/
├── VideoWallpaperApp/              # Main app target
│   ├── AppDelegate.swift           # App delegate with status bar
│   ├── ContentView.swift           # Main SwiftUI interface
│   ├── NetworkManager.swift        # Web scraping & downloads
│   ├── WallpaperManager.swift      # State management
│   ├── DesktopWindowController.swift # Desktop wallpaper window
│   ├── LockScreenManager.swift     # Lock screen file manager
│   ├── WallpaperHistoryView.swift  # History UI
│   ├── Assets.xcassets/           # App icons
│   └── VideoWallpaperApp.entitlements # Sandbox permissions
├── VideoWallpaperScreenSaver/      # Screen saver target
│   ├── VideoWallpaperScreenSaver.swift
│   └── VideoWallpaperScreenSaver.entitlements
├── VideoWallpaperApp.xcodeproj/    # Xcode project
├── Package.swift                   # Swift Package Manager
├── README.md                      # Documentation
└── .gitignore                     # Git ignore rules
```

## Key Features Implemented

- ✅ Searchable gallery with wallsflow.com integration
- ✅ Desktop video wallpaper with AVPlayerLayer
- ✅ Native screen saver plugin
- ✅ Lock screen integration (idleassetsd workaround)
- ✅ MacBook-inspired sleek UI
- ✅ Wallpaper history management
- ✅ Status bar integration
- ✅ SwiftSoup web scraping
- ✅ Complete entitlements configuration

## Troubleshooting

### Build Errors

**Missing SwiftSoup:**
- Ensure you added the package dependency in Xcode
- Check that SwiftSoup is linked in the target's frameworks

**Signing Issues:**
- Set your development team in project settings
- Enable automatic code signing

**Permission Errors:**
- Grant accessibility permissions in System Preferences
- Restart the app after granting permissions

### Runtime Issues

**Desktop wallpaper not showing:**
- Check accessibility permissions
- Verify video file exists in Documents/VideoWallpaper/Videos
- Try restarting the app

**Screen saver not appearing:**
- Verify .saver bundle is in ~/Library/Screen Savers/
- Check System Preferences screen saver settings
- Ensure video file is properly copied

**Lock screen changes not working:**
- Requires administrator privileges
- Check system directory permissions
- Ensure Apple Aerial videos exist on system

## Development Notes

- Target macOS 14.0 (Sonoma) or later
- Requires Swift 5.9+
- Uses SwiftUI for modern, declarative UI
- AVFoundation for video playback
- SwiftSoup for HTML parsing
- Follows Apple's Human Interface Guidelines

## License

This project is provided as-is for educational purposes.

## Support

For issues or questions, please check the README.md file or create an issue on GitHub.