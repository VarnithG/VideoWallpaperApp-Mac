# Video Wallpaper App

A macOS application that allows you to set video files as your desktop wallpaper, screen saver, and lock screen. Download videos directly from any URL and use them as live wallpapers.

## Features

- **Direct Video Downloads**: Download videos from any direct URL to your computer
- **Desktop Video Wallpaper**: Set downloaded videos as your desktop background
- **Screen Saver**: Use videos as your screen saver
- **Lock Screen Integration**: Set videos as your lock screen background
- **Local File Management**: Browse and manage your downloaded wallpapers
- **Video Preview**: Preview wallpapers before setting them
- **Simple Interface**: Easy-to-use interface with download and management sections

## How It Works

### Direct Download Approach
The app uses a direct download approach instead of web scraping:
1. **Download Section**: Enter any direct video URL to download
2. **Local Storage**: Videos are saved to `~/Documents/VideoWallpaper/Downloads/`
3. **My Downloads**: Browse your downloaded videos in the app
4. **File Access**: Open your downloads folder directly from the app
5. **Set Wallpaper**: Use any downloaded video as wallpaper/screen saver/lock screen

### Supported Video Sources
- Direct MP4 file URLs from any website
- Your own video files
- Public domain videos
- Personal video collections
- Any accessible video URL

## Building Without Xcode

The app can be built without Xcode using the provided scripts:

```bash
cd /Users/varnith/VideoWallpaperApp
./build.sh
./create_app_bundle.sh
open build/VideoWallpaperApp.app
```

## Required Permissions

For the app to work properly, you need to enable the following macOS permissions:

### 1. Accessibility Permission (Required for Desktop Wallpaper)
- **Why**: The app needs accessibility permission to display windows on your desktop behind other windows
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Accessibility
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Restart the app after enabling

### 2. Full Disk Access (Required for Screen Saver and Lock Screen)
- **Why**: The app needs access to system folders to install screen saver and lock screen files
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Full Disk Access
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Restart the app after enabling

### 3. Internet Access (Required for Downloading Videos)
- **Why**: The app needs internet access to download videos from URLs
- **How to enable**:
  1. Go to System Preferences > Security & Privacy > Privacy > Outgoing Connections
  2. Click the lock icon to make changes (requires admin password)
  3. Add "VideoWallpaperApp" to the list or check the box if already present
  4. Most apps have this enabled by default

### 4. Notification Permissions (Optional)
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

## Installation Instructions

1. **Build the app**:
   ```bash
   cd /Users/varnith/VideoWallpaperApp
   ./build.sh
   ./create_app_bundle.sh
   ```

2. **Enable permissions** (see Required Permissions section above)

3. **Run the app**:
   ```bash
   open build/VideoWallpaperApp.app
   ```

## How to Use

### Downloading Videos

1. **Open Download Section**: Click "Download Video" in the sidebar
2. **Enter Video URL**: Paste a direct video URL (e.g., `https://example.com/video.mp4`)
3. **Enter Title**: Give your wallpaper a name
4. **Click Download**: The video will be downloaded to your downloads folder
5. **Auto-redirect**: App automatically switches to "My Downloads" after download

### Setting Wallpapers

1. **Browse Downloads**: Click "My Downloads" in the sidebar
2. **Select Wallpaper**: Click on any downloaded wallpaper to preview
3. **Choose Type**: Click "Set as Desktop Wallpaper", "Set as Screen Saver", or "Set as Lock Screen"
4. **Enjoy**: Your wallpaper is now active

### Managing Downloads

1. **Open Folder**: Click "Open Folder" in the sidebar to access your downloads
2. **Delete Wallpapers**: Right-click on any wallpaper and select "Delete"
3. **Add Your Own**: You can also manually add video files to the downloads folder

### Downloads Folder Location

Your downloaded videos are stored at:
```
~/Documents/VideoWallpaper/Downloads/
```

You can:
- Access this folder directly from Finder
- Add your own video files to this folder
- They will appear in the app's "My Downloads" section
- Delete files directly from the folder

## Troubleshooting

### Wallpaper not showing on desktop
- Make sure Accessibility permission is enabled
- Check that the app is running in the background
- Try setting the wallpaper again
- Verify the video file exists in your downloads folder

### Download failed error
- Check your internet connection
- Verify the video URL is direct and accessible
- Ensure the URL ends with .mp4 or is a direct video link
- Check if Outgoing Connections permission is enabled

### Video won't play
- Verify the video file is not corrupted
- Check that the video format is supported (MP4 recommended)
- Try downloading the video again
- Test the video file in QuickTime Player

### Screen saver not working
- Make sure Full Disk Access is enabled
- Check that the screen saver file was installed correctly
- Try setting the screen saver again
- Verify the video file exists in your downloads folder

### Lock screen not working
- Make sure Full Disk Access is enabled
- Check that the lock screen file was installed correctly
- Try setting the lock screen again
- Verify the video file exists in your downloads folder

## Video URL Examples

These are examples of direct video URLs you can use:

- **Sample Videos**: `https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4`
- **Your Own Files**: Upload videos to cloud storage and use direct links
- **Public Domain**: Use videos from public domain sources
- **Personal Files**: Use videos from your own servers or storage

## Tips for Best Results

1. **Use Direct URLs**: Make sure the URL points directly to the video file
2. **MP4 Format**: MP4 files work best with macOS
3. **Reasonable Size**: Large files may take longer to download
4. **Stable Connection**: Ensure good internet connection for downloads
5. **Backup**: Keep backups of your favorite wallpapers

## Technical Implementation

### Download Management
- Direct URL downloads using URLSession
- Automatic file management in designated folder
- Progress tracking for downloads
- Error handling for failed downloads

### File System
- Dedicated downloads folder in Documents
- Automatic directory creation
- File conflict resolution
- Easy file access and management

### Wallpaper Management
- Desktop wallpaper using AVPlayerLayer
- Screen saver plugin integration
- Lock screen file replacement
- Video preview before setting

## Architecture

### MVVM Pattern
- **Model**: `Wallpaper` struct for video data
- **View**: SwiftUI views for interface
- **ViewModel**: `NetworkManager` and `WallpaperManager`

### State Management
- `@Published` properties for reactive updates
- File-based storage for downloads
- Local file system integration

## Dependencies

- **AVFoundation**: Video playback
- **ScreenSaver**: Screen saver framework
- **SwiftUI**: User interface
- **Foundation**: File system and networking

## Security

- Downloads stored in user's Documents folder
- No external dependencies
- No cloud storage of your videos
- Local file management only
- No data collection or tracking

## Future Enhancements

Potential future features:
- Thumbnail generation for local videos
- Video editing capabilities
- Playlist support
- Cloud backup integration
- More format support

## Credits

- Built with SwiftUI and AVFoundation
- No external dependencies beyond standard macOS frameworks
- User maintains full control of their video files