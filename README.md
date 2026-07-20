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
3. Build and run the project

### Permissions Required

The app requires the following macOS permissions for full functionality:

#### 1. Accessibility Permission (Required for Desktop Wallpaper)
- **Why**: The app needs accessibility permission to display windows on your desktop behind other windows
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Accessibility
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Restart the app after enabling

#### 2. Full Disk Access (Required for Screen Saver and Lock Screen)
- **Why**: The app needs access to system folders to install screen saver and lock screen files
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Full Disk Access
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Restart the app after enabling

#### 3. Internet Access (Required for Downloading Wallpapers)
- **Why**: The app needs internet access to download wallpapers from wallsflow.com
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Outgoing Connections
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Most apps have this enabled by default

#### 4. Notification Permissions (Optional)
- **Why**: The app can send notifications when wallpapers are set
- **How to enable**:
  1. Go to System Preferences > Notifications
  2. Find VideoWallpaperApp in the list
  3. Enable notifications if desired

#### First Launch Setup
When you first launch the app, you may see prompts for these permissions. Make sure to:
- Click "Open System Preferences" when prompted
- Follow the steps above for each permission
- Restart the app after granting permissions
- If prompts don't appear, manually enable them in System Preferences

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

### Network Manager (Native Swift Parsing)

The `NetworkManager` class handles web scraping from wallsflow.com using native Swift string parsing:

```swift
// Search for wallpapers
let wallpapers = try await networkManager.searchWallpapers(query: "nature")

// Download video
let progress = try await networkManager.downloadVideo(from: url, to: destinationURL)
```

Key features:
- Native Swift HTML parsing with regex patterns
- Multiple selector patterns for robustness
- Direct MP4 link extraction as fallback
- Progress tracking for downloads
- No external dependencies required

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

- **AVFoundation**: Video playback
- **ScreenSaver**: Screen saver framework
- **SwiftUI**: User interface
- **Foundation**: HTML parsing with native Swift (no external dependencies)

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