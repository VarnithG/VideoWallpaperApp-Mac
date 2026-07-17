# Video Wallpaper App

A macOS application that allows users to set video files as desktop wallpaper, screensaver, and lock screen backgrounds. Features a searchable gallery interface that can download live wallpapers from wallsflow.com.

## Features

- **Searchable Gallery**: Browse and search for live wallpapers from wallsflow.com
- **Desktop Video Wallpaper**: Set videos as your desktop background using AVPlayerLayer
- **Screen Saver**: Native macOS screen saver plugin with video playback
- **Lock Screen Integration**: Replace system lock screen wallpapers (requires admin privileges)
- **Sleek UI**: MacBook-inspired interface with minimal design
- **Wallpaper History**: Track and reuse previously downloaded wallpapers

## Project Structure

```
VideoWallpaperApp/
├── VideoWallpaperApp.xcodeproj/
│   └── project.pbxproj
├── VideoWallpaperApp/
│   ├── AppDelegate.swift              # Main app delegate with status bar
│   ├── ContentView.swift              # Main SwiftUI interface
│   ├── NetworkManager.swift           # Web scraping and download manager
│   ├── WallpaperManager.swift         # Wallpaper state management
│   ├── DesktopWindowController.swift  # Desktop video window controller
│   ├── LockScreenManager.swift        # Lock screen file manager
│   ├── WallpaperHistoryView.swift    # Wallpaper history UI
│   ├── VideoWallpaperApp.entitlements # App sandbox entitlements
│   └── Assets.xcassets                # App assets
├── VideoWallpaperScreenSaver/
│   ├── VideoWallpaperScreenSaver.swift    # Screen saver plugin
│   └── VideoWallpaperScreenSaver.entitlements
└── Package.swift                     # Swift Package Manager dependencies
```

## Targets

### 1. VideoWallpaperApp (Main Application)
- **Purpose**: Main app with SwiftUI interface
- **Frameworks**: SwiftUI, AVFoundation, SwiftSoup
- **Key Components**:
  - Searchable gallery with networking
  - Desktop wallpaper window controller
  - Lock screen file manager
  - Status bar integration

### 2. VideoWallpaperScreenSaver (Screen Saver Plugin)
- **Purpose**: Native macOS screen saver
- **Frameworks**: ScreenSaver, AVFoundation
- **Key Components**:
  - Video playback in screen saver context
  - Configuration sheet for settings
  - Loop and mute controls

## Installation

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later

### Build Steps

1. Clone the repository
2. Open `VideoWallpaperApp.xcodeproj` in Xcode
3. Add SwiftSoup dependency via Swift Package Manager:
   - File > Add Package Dependencies
   - Enter: `https://github.com/scinfu/SwiftSoup.git`
   - Select version 2.6.0 or later
4. Build and run the project

### Permissions Required

The app requires the following macOS permissions:

1. **Accessibility**: For desktop wallpaper control
   - System Preferences > Security & Privacy > Privacy > Accessibility
   - Enable "Video Wallpaper"

2. **Full Disk Access**: For lock screen modification (optional)
   - System Preferences > Security & Privacy > Privacy > Full Disk Access
   - Enable "Video Wallpaper"

## Usage

### Setting Desktop Wallpaper

1. Search for wallpapers using the search bar
2. Click on a wallpaper to preview
3. Click "Set as Desktop Wallpaper"
4. The video will play behind your desktop icons

### Setting Screen Saver

1. Search and select a wallpaper
2. Click "Set as Screen Saver"
3. Open System Preferences > Desktop & Screen Saver
4. Select "Video Wallpaper Screen Saver"

### Setting Lock Screen

1. Search and select a wallpaper
2. Click "Set as Lock Screen"
3. The app will replace an Apple Aerial video in the system directory
4. **Note**: Requires administrator privileges

### Managing History

1. Click the "History" tab
2. View previously downloaded wallpapers
3. Reuse wallpapers with one click
4. Clear history when needed

## Technical Implementation

### Network Manager (SwiftSoup)

The `NetworkManager` class handles web scraping from wallsflow.com:

```swift
// Search for wallpapers
let wallpapers = try await networkManager.searchWallpapers(query: "nature")

// Download video
let progress = try await networkManager.downloadVideo(from: url, to: destinationURL)
```

Key features:
- HTML parsing with SwiftSoup
- Multiple selector patterns for robustness
- Direct MP4 link extraction as fallback
- Progress tracking for downloads

### Desktop Window Controller

The `DesktopWindowController` creates a borderless window:

```swift
let window = NSWindow(
    contentRect: screen.visibleRect,
    styleMask: [.borderless, .fullSizeContentView],
    backing: .buffered,
    defer: false
)

window.level = CGWindowLevelForKey(.desktopWindow)
window.ignoresMouseEvents = true
```

Key features:
- Window level below desktop icons
- AVPlayerLayer for video playback
- Automatic screen resize handling
- Loop and mute controls

### Lock Screen Manager

The `LockScreenManager` handles system file operations:

```swift
// User-level (no admin required)
lockScreenManager.setLockScreenVideo(url: url, wallpaper: wallpaper)

// System-level (requires admin)
lockScreenManager.setLockScreenVideoSystemLevel(url: url, wallpaper: wallpaper)
```

Key features:
- UUID-based filename generation
- Automatic backup of original files
- User and system directory support
- Metadata tracking

### Screen Saver Plugin

The screen saver uses the native ScreenSaver framework:

```swift
class VideoWallpaperScreenSaver: ScreenSaverView {
    override func startAnimation() {
        super.startAnimation()
        setupPlayer(with: videoURL)
    }
}
```

Key features:
- Native screen saver integration
- Configuration sheet
- Loop and mute controls
- Preview mode support

## Architecture

### MVVM Pattern

- **Model**: `Wallpaper` struct, network models
- **View**: SwiftUI views, screen saver views
- **ViewModel**: `NetworkManager`, `WallpaperManager`

### Coordinator Pattern

- `AppDelegate` coordinates main app flow
- `DesktopWindowController` manages desktop wallpaper
- `LockScreenManager` handles lock screen operations
- Individual view controllers for UI sections

### State Management

- `@Published` properties for reactive updates
- `UserDefaults` for persistent settings
- File-based metadata for wallpaper tracking

## Dependencies

- **SwiftSoup**: HTML parsing for web scraping
- **AVFoundation**: Video playback
- **ScreenSaver**: Screen saver framework
- **SwiftUI**: User interface

## Troubleshooting

### Desktop wallpaper not showing
- Ensure accessibility permissions are granted
- Check that the video file exists in Documents/VideoWallpaper/Videos
- Try restarting the app

### Screen saver not appearing
- Verify the screen saver is installed in ~/Library/Screen Savers/
- Check System Preferences > Desktop & Screen Saver
- Ensure the video file is properly copied

### Lock screen changes not working
- Verify administrator privileges
- Check system directory permissions
- Ensure Apple Aerial videos exist on system

## License

This project is provided as-is for educational purposes.

## Credits

- Wallpaper content sourced from wallsflow.com
- Inspired by Apple's Aerial screen saver
- Built with Swift and SwiftUI