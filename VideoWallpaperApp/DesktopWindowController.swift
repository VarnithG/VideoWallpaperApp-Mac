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
            contentRect: NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.level = .init(Int(CGWindowLevelForKey(.desktopWindow)))
        window.backgroundColor = NSColor.clear
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
        // Validate URL before attempting to play
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("Video file does not exist: \(url.path)")
            return
        }
        
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            print("Video file is not readable: \(url.path)")
            return
        }
        
        self.videoURL = url
        
        // Stop current playback
        stopPlayback()
        
        // Create player with proper error handling
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

// Lock Screen Manager is implemented in LockScreenManager.swift