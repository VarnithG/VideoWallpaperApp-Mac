import Foundation
import Cocoa
import Combine
import UserNotifications

// MARK: - Wallpaper Manager
class WallpaperManager: ObservableObject {
    static let shared = WallpaperManager()
    
    @Published var currentWallpaper: Wallpaper?
    @Published var isMuted = false
    @Published var shouldLoop = true
    @Published var reduceMotion = false
    @Published var lowPowerMode = false
    
    private let desktopWindowController = DesktopWindowController.shared
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var wallpaperDirectory: URL {
        documentsDirectory.appendingPathComponent("VideoWallpaper")
    }
    
    private var videoDirectory: URL {
        wallpaperDirectory.appendingPathComponent("Videos")
    }
    
    private var metadataFile: URL {
        wallpaperDirectory.appendingPathComponent("metadata.json")
    }
    
    private init() {
        setupDirectories()
        loadMetadata()
    }
    
    // MARK: - Setup Directories
    private func setupDirectories() {
        try? fileManager.createDirectory(at: wallpaperDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Save Metadata
    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(currentWallpaper) else { return }
        try? data.write(to: metadataFile)
    }
    
    // MARK: - Load Metadata
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFile.path),
              let data = fileManager.contents(atPath: metadataFile.path),
              let wallpaper = try? JSONDecoder().decode(Wallpaper.self, from: data) else {
            return
        }
        
        currentWallpaper = wallpaper
        
        // Restore desktop wallpaper if exists
        let videoPath = videoDirectory.appendingPathComponent("\(wallpaper.id).mp4")
        if fileManager.fileExists(atPath: videoPath.path) {
            setDesktopWallpaper(url: videoPath, wallpaper: wallpaper, restore: true)
        }
    }
    
    // MARK: - Set Desktop Wallpaper
    func setDesktopWallpaper(url: URL, wallpaper: Wallpaper, restore: Bool = false) {
        currentWallpaper = wallpaper
        saveMetadata()
        
        desktopWindowController.playVideo(at: url, loop: shouldLoop)
        desktopWindowController.setMuted(isMuted)
        
        if !restore {
            showNotification(title: "Desktop Wallpaper", message: "Video wallpaper set successfully")
        }
    }
    
    // MARK: - Set Screen Saver
    func setScreenSaver(url: URL, wallpaper: Wallpaper) {
        // Copy video to screen saver library
        let screenSaverDirectory = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Screen Savers")
        
        try? fileManager.createDirectory(at: screenSaverDirectory, withIntermediateDirectories: true)
        
        let destinationURL = screenSaverDirectory.appendingPathComponent("VideoWallpaper.mp4")
        
        // Copy file
        try? fileManager.removeItem(at: destinationURL)
        try? fileManager.copyItem(at: url, to: destinationURL)
        
        // Save path to UserDefaults for screen saver
        UserDefaults.standard.set(destinationURL.path, forKey: "ScreenSaverVideoPath")
        
        showNotification(title: "Screen Saver", message: "Video screen saver set successfully")
    }
    
    // MARK: - Stop Desktop Wallpaper
    func stopDesktopWallpaper() {
        desktopWindowController.stopPlayback()
        currentWallpaper = nil
        saveMetadata()
    }
    
    // MARK: - Pause Desktop Wallpaper
    func pauseDesktopWallpaper() {
        desktopWindowController.pausePlayback()
    }
    
    // MARK: - Resume Desktop Wallpaper
    func resumeDesktopWallpaper() {
        desktopWindowController.resumePlayback()
    }
    
    // MARK: - Get Downloaded Wallpapers
    func getDownloadedWallpapers() -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        
        guard let files = try? fileManager.contentsOfDirectory(at: videoDirectory, includingPropertiesForKeys: nil) else {
            return wallpapers
        }
        
        for file in files where file.pathExtension == "mp4" {
            let wallpaper = Wallpaper(
                id: file.deletingPathExtension().lastPathComponent,
                title: file.lastPathComponent,
                thumbnailURL: file,
                videoURL: file
            )
            wallpapers.append(wallpaper)
        }
        
        return wallpapers
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        let cacheDirectory = wallpaperDirectory.appendingPathComponent("Thumbnails")
        
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Reset All
    func resetAll() {
        stopDesktopWallpaper()
        
        try? fileManager.removeItem(at: wallpaperDirectory)
        setupDirectories()
        
        // Reset screen saver
        UserDefaults.standard.removeObject(forKey: "ScreenSaverVideoPath")
    }
    
    // MARK: - Show Notification
    private func showNotification(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        center.add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}