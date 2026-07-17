import Cocoa
import ScreenSaver
import AVFoundation

// MARK: - Main Screen Saver View
class VideoWallpaperScreenSaver: ScreenSaverView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?
    private var previewMode = false
    
    // Configuration
    private var videoURL: URL?
    private var shouldLoop = true
    private var isMuted = true
    
    // MARK: - Initialization
    override init?(frame: NSRect, isPreview: Bool) {
        self.previewMode = isPreview
        super.init(frame: frame, isPreview: isPreview)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup View
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        // Load configuration
        loadConfiguration()
        
        // Find video file
        if let videoPath = findVideoFile() {
            videoURL = URL(fileURLWithPath: videoPath)
        }
    }
    
    // MARK: - Start Animation
    override func startAnimation() {
        super.startAnimation()
        
        guard let videoURL = videoURL else {
            showNoVideoMessage()
            return
        }
        
        setupPlayer(with: videoURL)
    }
    
    // MARK: - Stop Animation
    override func stopAnimation() {
        super.stopAnimation()
        
        player?.pause()
        player = nil
        looper?.disableLooping()
        looper = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }
    
    // MARK: - Animate One Frame
    override func animateOneFrame() {
        // AVPlayer handles its own timing, so this is optional
        // Called at screen refresh rate
    }
    
    // MARK: - Setup Player
    private func setupPlayer(with url: URL) {
        // Create player item
        let playerItem = AVPlayerItem(url: url)
        
        // Create player
        let player: AVPlayer
        if shouldLoop && !previewMode {
            let queuePlayer = AVQueuePlayer(playerItem: playerItem)
            player = queuePlayer
            
            // Setup looper
            looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        } else {
            player = AVPlayer(playerItem: playerItem)
        }
        
        self.player = player
        
        // Mute if configured
        player.isMuted = isMuted
        
        // Setup player layer
        setupPlayerLayer(with: player)
        
        // Start playback
        player.play()
        
        // Handle player end for non-looping mode
        if !shouldLoop {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinish),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
        }
    }
    
    // MARK: - Setup Player Layer
    private func setupPlayerLayer(with player: AVPlayer) {
        // Remove existing layer
        playerLayer?.removeFromSuperlayer()
        
        // Create new player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        
        // Add to view layer
        layer?.addSublayer(playerLayer)
        
        self.playerLayer = playerLayer
        
        // Auto-resize
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
    }
    
    // MARK: - Handle Resize
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        
        playerLayer?.frame = bounds
    }
    
    // MARK: - Player Did Finish
    @objc private func playerDidFinish(_ notification: Notification) {
        if !shouldLoop {
            player?.seek(to: .zero)
            player?.play()
        }
    }
    
    // MARK: - Show No Video Message
    private func showNoVideoMessage() {
        let textLayer = CATextLayer()
        textLayer.string = "No video file found"
        textLayer.fontSize = 24
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.alignmentMode = .center
        textLayer.frame = bounds
        
        layer?.addSublayer(textLayer)
    }
    
    // MARK: - Find Video File
    private func findVideoFile() -> String? {
        // Try multiple locations
        
        // 1. Screen Saver Library
        let screenSaverPath = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Screen Savers/VideoWallpaper.mp4")
        
        if FileManager.default.fileExists(atPath: screenSaverPath.path) {
            return screenSaverPath.path
        }
        
        // 2. Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoWallpaper/Videos")
        
        if let files = try? FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "mp4" {
                return file.path
            }
        }
        
        // 3. Application Support
        let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoWallpaper")
        
        if let files = try? FileManager.default.contentsOfDirectory(at: appSupportPath, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "mp4" {
                return file.path
            }
        }
        
        return nil
    }
    
    // MARK: - Load Configuration
    private func loadConfiguration() {
        // Try to load configuration from UserDefaults
        let defaults = UserDefaults.standard
        
        shouldLoop = defaults.bool(forKey: "ScreenSaverLoop")
        isMuted = defaults.bool(forKey: "ScreenSaverMuted")
        
        // Try to load specific video path
        if let videoPath = defaults.string(forKey: "ScreenSaverVideoPath") {
            videoURL = URL(fileURLWithPath: videoPath)
        }
    }
    
    // MARK: - Configuration Sheet
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        sheet.title = "Video Wallpaper Screen Saver Settings"
        sheet.center()
        
        let viewController = ConfigureViewController()
        viewController.onConfigurationChanged = { [weak self] in
            self?.loadConfiguration()
        }
        
        sheet.contentViewController = viewController
        
        return sheet
    }
}

// MARK: - Configure View Controller
class ConfigureViewController: NSViewController {
    var onConfigurationChanged: (() -> Void)?
    
    private var loopToggle: NSSwitch!
    private var muteToggle: NSSwitch!
    private var videoPathField: NSTextField!
    private var browseButton: NSButton!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        setupUI()
    }
    
    private func setupUI() {
        // Title
        let title = NSTextField(labelWithString: "Screen Saver Settings")
        title.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        title.frame = NSRect(x: 20, y: 260, width: 360, height: 24)
        view.addSubview(title)
        
        // Loop toggle
        loopToggle = NSSwitch(frame: NSRect(x: 20, y: 220, width: 360, height: 24))
        loopToggle.state = UserDefaults.standard.bool(forKey: "ScreenSaverLoop") ? .on : .off
        loopToggle.title = "Loop playback"
        loopToggle.target = self
        loopToggle.action = #selector(loopToggleChanged)
        view.addSubview(loopToggle)
        
        // Mute toggle
        muteToggle = NSSwitch(frame: NSRect(x: 20, y: 180, width: 360, height: 24))
        muteToggle.state = UserDefaults.standard.bool(forKey: "ScreenSaverMuted") ? .on : .off
        muteToggle.title = "Mute audio"
        muteToggle.target = self
        muteToggle.action = #selector(muteToggleChanged)
        view.addSubview(muteToggle)
        
        // Video path label
        let pathLabel = NSTextField(labelWithString: "Video file path:")
        pathLabel.frame = NSRect(x: 20, y: 140, width: 360, height: 20)
        view.addSubview(pathLabel)
        
        // Video path field
        videoPathField = NSTextField(frame: NSRect(x: 20, y: 110, width: 280, height: 24))
        videoPathField.stringValue = UserDefaults.standard.string(forKey: "ScreenSaverVideoPath") ?? ""
        view.addSubview(videoPathField)
        
        // Browse button
        browseButton = NSButton(frame: NSRect(x: 310, y: 110, width: 70, height: 24))
        browseButton.title = "Browse"
        browseButton.target = self
        browseButton.action = #selector(browseVideo)
        view.addSubview(browseButton)
        
        // Info text
        let infoText = NSTextField(wrappingLabelWithString: "Leave path empty to use the last downloaded wallpaper from the main app.")
        infoText.frame = NSRect(x: 20, y: 60, width: 360, height: 40)
        infoText.textColor = .secondaryLabelColor
        infoText.font = NSFont.systemFont(ofSize: 11)
        view.addSubview(infoText)
        
        // Save button
        let saveButton = NSButton(frame: NSRect(x: 290, y: 20, width: 90, height: 30))
        saveButton.title = "Save"
        saveButton.bezelStyle = .rounded
        saveButton.target = self
        saveButton.action = #selector(saveConfiguration)
        view.addSubview(saveButton)
    }
    
    @objc private func loopToggleChanged() {
        UserDefaults.standard.set(loopToggle.state == .on, forKey: "ScreenSaverLoop")
    }
    
    @objc private func muteToggleChanged() {
        UserDefaults.standard.set(muteToggle.state == .on, forKey: "ScreenSaverMuted")
    }
    
    @objc private func browseVideo() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["mp4", "mov", "m4v"]
        panel.allowsMultipleSelection = false
        
        if panel.runModal() == .OK, let url = panel.url {
            videoPathField.stringValue = url.path
        }
    }
    
    @objc private func saveConfiguration() {
        UserDefaults.standard.set(videoPathField.stringValue, forKey: "ScreenSaverVideoPath")
        onConfigurationChanged?()
        
        if let window = view.window {
            window.sheetParent?.endSheet(window)
        }
    }
}

// MARK: - Preview Helper
extension VideoWallpaperScreenSaver {
    // This method is called by System Preferences for preview
    override func draw(_ rect: NSRect) {
        super.draw(rect)
        
        // Draw black background
        NSColor.black.setFill()
        bounds.fill()
    }
}