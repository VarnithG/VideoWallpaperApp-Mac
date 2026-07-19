import Foundation
import Cocoa
import UserNotifications

// MARK: - Lock Screen Manager
class LockScreenManager {
    static let shared = LockScreenManager()
    
    private let fileManager = FileManager.default
    
    // System idleassets directory for macOS Sonoma+
    private let idleAssetsDirectory = "/Library/Application Support/com.apple.idleassetsd/Customer/"
    
    // User-level alternative (doesn't require admin privileges)
    private let userIdleAssetsDirectory: URL = {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Application Support/com.apple.idleassetsd/Customer/")
    }()
    
    private init() {}
    
    // MARK: - Set Lock Screen Video
    func setLockScreenVideo(url: URL, wallpaper: Wallpaper) {
        // Try user-level directory first (no admin required)
        let targetDirectory = userIdleAssetsDirectory
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        
        // Generate UUID-based filename to match Apple's naming convention
        let uuidFilename = UUID().uuidString + ".mov"
        let destinationURL = targetDirectory.appendingPathComponent(uuidFilename)
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }
        
        // Copy video file
        do {
            try fileManager.copyItem(at: url, to: destinationURL)
            
            // Save metadata for tracking
            saveLockScreenMetadata(wallpaper: wallpaper, filename: uuidFilename)
            
            showNotification(title: "Lock Screen", message: "Lock screen video set successfully")
        } catch {
            showNotification(title: "Lock Screen", message: "Failed to set lock screen: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Set Lock Screen Video (System Level - Requires Admin)
    func setLockScreenVideoSystemLevel(url: URL, wallpaper: Wallpaper) {
        // Check if we have access to the system idleassets directory
        guard fileManager.fileExists(atPath: idleAssetsDirectory) else {
            showNotification(title: "Lock Screen", message: "Cannot access system lock screen directory. Requires administrator privileges.")
            return
        }
        
        // Find an existing Apple Aerial video
        guard let aerialVideo = findAerialVideo() else {
            showNotification(title: "Lock Screen", message: "No Apple Aerial videos found to replace.")
            return
        }
        
        // Backup original
        let backupURL = aerialVideo.appendingPathExtension("backup")
        
        if !fileManager.fileExists(atPath: backupURL.path) {
            try? fileManager.copyItem(at: aerialVideo, to: backupURL)
        }
        
        // Copy our video to replace it
        do {
            try fileManager.removeItem(at: aerialVideo)
            try fileManager.copyItem(at: url, to: aerialVideo)
            
            // Save metadata
            saveLockScreenMetadata(wallpaper: wallpaper, filename: aerialVideo.lastPathComponent)
            
            showNotification(title: "Lock Screen", message: "Lock screen video set successfully")
        } catch {
            showNotification(title: "Lock Screen", message: "Failed to set lock screen: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Find Aerial Video
    private func findAerialVideo() -> URL? {
        guard let files = try? fileManager.contentsOfDirectory(at: URL(fileURLWithPath: idleAssetsDirectory), includingPropertiesForKeys: nil) else {
            return nil
        }
        
        // Find .mov files (Apple Aerial format)
        for file in files where file.pathExtension == "mov" {
            return file
        }
        
        return nil
    }
    
    // MARK: - Save Lock Screen Metadata
    private func saveLockScreenMetadata(wallpaper: Wallpaper, filename: String) {
        let metadata: [String: Any] = [
            "wallpaper": (try? JSONEncoder().encode(wallpaper)) as Any,
            "filename": filename,
            "date": Date()
        ]
        
        let metadataURL = userIdleAssetsDirectory.appendingPathComponent("lockscreen_metadata.json")
        
        if let data = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted) {
            try? data.write(to: metadataURL)
        }
    }
    
    // MARK: - Restore Original Lock Screen
    func restoreOriginalLockScreen() {
        guard let aerialVideo = findAerialVideo() else {
            showNotification(title: "Lock Screen", message: "No lock screen video found to restore")
            return
        }
        
        let backupURL = aerialVideo.appendingPathExtension("backup")
        
        guard fileManager.fileExists(atPath: backupURL.path) else {
            showNotification(title: "Lock Screen", message: "No backup found to restore")
            return
        }
        
        do {
            try fileManager.removeItem(at: aerialVideo)
            try fileManager.copyItem(at: backupURL, to: aerialVideo)
            
            showNotification(title: "Lock Screen", message: "Original lock screen restored")
        } catch {
            showNotification(title: "Lock Screen", message: "Failed to restore: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clear User Lock Screen Videos
    func clearUserLockScreenVideos() {
        do {
            let files = try fileManager.contentsOfDirectory(at: userIdleAssetsDirectory, includingPropertiesForKeys: nil)
            
            for file in files {
                try fileManager.removeItem(at: file)
            }
            
            showNotification(title: "Lock Screen", message: "User lock screen videos cleared")
        } catch {
            showNotification(title: "Lock Screen", message: "Failed to clear: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Current Lock Screen Info
    func getCurrentLockScreenInfo() -> (wallpaper: Wallpaper?, filename: String?) {
        let metadataURL = userIdleAssetsDirectory.appendingPathComponent("lockscreen_metadata.json")
        
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = fileManager.contents(atPath: metadataURL.path),
              let metadata = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let wallpaperData = metadata["wallpaper"] as? Data,
              let wallpaper = try? JSONDecoder().decode(Wallpaper.self, from: wallpaperData),
              let filename = metadata["filename"] as? String else {
            return (nil, nil)
        }
        
        return (wallpaper, filename)
    }
    
    // MARK: - Check System Directory Access
    func hasSystemDirectoryAccess() -> Bool {
        return fileManager.fileExists(atPath: idleAssetsDirectory) && fileManager.isWritableFile(atPath: idleAssetsDirectory)
    }
    
    // MARK: - Request Admin Privileges Helper
    func requestAdminPrivileges() -> Bool {
        let script = """
        do shell script "echo 'Admin access test'" with administrator privileges
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            _ = appleScript.executeAndReturnError(&error)
            return error == nil
        }
        
        return false
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