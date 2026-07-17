import Cocoa
import AVFoundation
import Combine

// MARK: - Desktop Window Controller
class DesktopWindowController: NSWindowController {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoURL: URL?
    private var looper: AVPlayerLooper?
    private var cancellables = Set<AnyCancellable>()
    
    // Singleton instance
    static let shared = DesktopWindowController()
    
    override init(window: NSWindow?) {
        super.init(window: window)
        setupWindow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupWindow()
    }
    
    // MARK: - Setup Window
    private func setupWindow() {
        let window = NSWindow(
            contentRect: NSScreen.main?.visibleRect ?? NSRect(x: 0, y: 0, width: 1920, height: 1080),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = CGWindowLevelForKey(.desktopWindow)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.title = "Desktop Wallpaper"
        
        self.window = window
        self.windowFrameAutosaveName = "DesktopWallpaperWindow"
        
        setupObservers()
    }
    
    // MARK: - Setup Observers
    private func setupObservers() {
        // Observe screen changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updateWindowFrame()
            }
            .store(in: &cancellables)
        
        // Observe screen profile changes
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                self?.updateWindowFrame()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Update Window Frame
    private func updateWindowFrame() {
        guard let screen = NSScreen.main else { return }
        
        let windowFrame = NSRect(
            x: screen.frame.origin.x,
            y: screen.frame.origin.y,
            width: screen.frame.width,
            height: screen.frame.height
        )
        
        window?.setFrame(windowFrame, display: true)
    }
    
    // MARK: - Play Video
    func playVideo(at url: URL, loop: Bool = true) {
        self.videoURL = url
        
        // Stop current playback
        stopPlayback()
        
        // Create player
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        self.player = player
        
        // Setup looper if needed
        if loop {
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            self.player = queuePlayer
            
            looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        }
        
        // Setup player layer
        setupPlayerLayer()
        
        // Start playback
        player.play()
        
        // Show window
        window?.orderFront(nil)
        window?.setIsVisible(true)
    }
    
    // MARK: - Setup Player Layer
    private func setupPlayerLayer() {
        guard let player = player, let contentView = window?.contentView else { return }
        
        // Remove existing player layer
        playerLayer?.removeFromSuperlayer()
        
        // Create new player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = contentView.bounds
        
        // Add to content view layer
        contentView.layer = CALayer()
        contentView.wantsLayer = true
        contentView.layer?.addSublayer(playerLayer)
        
        self.playerLayer = playerLayer
        
        // Auto-resize with window
        contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.publisher(for: NSView.frameDidChangeNotification, object: contentView)
            .sink { [weak self] _ in
                self?.playerLayer?.frame = contentView.bounds
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Stop Playback
    func stopPlayback() {
        player?.pause()
        player = nil
        looper?.disableLooping()
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        
        window?.setIsVisible(false)
        window?.orderOut(nil)
    }
    
    // MARK: - Pause Playback
    func pausePlayback() {
        player?.pause()
    }
    
    // MARK: - Resume Playback
    func resumePlayback() {
        player?.play()
    }
    
    // MARK: - Set Volume
    func setVolume(_ volume: Float) {
        player?.volume = volume
    }
    
    // MARK: - Mute
    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }
    
    // MARK: - Get Current Video URL
    func getCurrentVideoURL() -> URL? {
        return videoURL
    }
    
    // MARK: - Is Playing
    func isPlaying() -> Bool {
        return player?.rate != 0
    }
}

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
        
        // Set as default screen saver
        setScreenSaverModule("VideoWallpaperScreenSaver")
        
        showNotification(title: "Screen Saver", message: "Video screen saver set successfully")
    }
    
    // MARK: - Set Lock Screen
    func setLockScreen(url: URL, wallpaper: Wallpaper) {
        // Lock screen functionality is handled by LockScreenManager
        // This is called from ContentView
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
        setScreenSaverModule("")
    }
    
    // MARK: - Set Screen Saver Module
    private func setScreenSaverModule(_ moduleName: String) {
        let script = """
        tell application "System Events"
            tell current desktop
                set pictures folder to "\(moduleName)"
            end tell
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
    
    // MARK: - Show Notification
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// Lock Screen Manager is implemented in LockScreenManager.swift