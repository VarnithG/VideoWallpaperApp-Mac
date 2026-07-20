import SwiftUI
import AVFoundation
import Cocoa
import Foundation

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    @State private var videoURL = ""
    @State private var videoTitle = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var showingPreview = false
    @State private var showingSettings = false
    @State private var selectedSection: WebsiteSection?
    @State private var showingError = false
    @State private var errorMessage: String?
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    
    private let gridItemLayout = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebarView
            
            // Main Content
            mainContentView
        }
        .onAppear {
            // Load local downloads on app launch
            Task {
                networkManager.loadLocalDownloads()
            }
        }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperPreviewView(wallpaper: wallpaper)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Logo/Header
            VStack(spacing: 8) {
                Image(systemName: "video.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                Text("Video Wallpaper")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.vertical, 20)
            
            Divider()
            
            // Sections
            VStack(alignment: .leading, spacing: 2) {
                ForEach(networkManager.sections) { section in
                    Button(action: {
                        selectedSection = section
                        handleSectionSelection(section)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: section.id == "download" ? "arrow.down.circle" : "folder.fill")
                                .font(.system(size: 16))
                            
                            Text(section.name)
                                .font(.system(size: 14))
                                .foregroundColor(selectedSection?.id == section.id ? .white : .primary)
                            
                            Spacer()
                            
                            if selectedSection?.id == section.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(selectedSection?.id == section.id ? Color.blue : Color.clear)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Downloads folder info
            VStack(alignment: .leading, spacing: 8) {
                Text("Downloads Folder:")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(networkManager.getDownloadsDirectory().path)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Button(action: {
                    NSWorkspace.shared.open(networkManager.getDownloadsDirectory())
                }) {
                    Text("Open Folder")
                        .font(.system(size: 11))
                }
                .buttonStyle(.link)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(width: 220)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if selectedSection?.id == "download" {
                downloadView
            } else {
                wallpaperGridView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedSection?.name ?? "Video Wallpaper")
                    .font(.system(size: 24, weight: .bold))
                
                Text("\(networkManager.wallpapers.count) wallpapers")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Download View
    private var downloadView: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Download Video")
                    .font(.system(size: 20, weight: .bold))
                
                Text("Enter a direct video URL to download")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Video URL")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("https://example.com/video.mp4", text: $videoURL)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Title")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("My Wallpaper", text: $videoTitle)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button(action: {
                    Task {
                        await downloadVideo()
                    }
                }) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Downloading...")
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download Video")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(videoURL.isEmpty || videoTitle.isEmpty || isDownloading)
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Popular Video Sources:")
                    .font(.system(size: 13, weight: .medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Direct MP4 files from any website")
                    Text("• Your own video files")
                    Text("• Public domain videos")
                }
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(24)
    }
    
    // MARK: - Wallpaper Grid View
    private var wallpaperGridView: some View {
        VStack(spacing: 0) {
            if networkManager.isLoading {
                loadingView
            } else if networkManager.wallpapers.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItemLayout, spacing: 16) {
                        ForEach(networkManager.wallpapers) { wallpaper in
                            WallpaperGridItem(wallpaper: wallpaper)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        try? networkManager.deleteWallpaper(wallpaper)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture {
                                    selectedWallpaper = wallpaper
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading wallpapers...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No wallpapers downloaded")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Download videos from the Download section")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Handle Section Selection
    private func handleSectionSelection(_ section: WebsiteSection) {
        if section.id == "my_downloads" {
            _ = networkManager.loadLocalDownloads()
        }
    }
    
    // MARK: - Download Video
    private func downloadVideo() async {
        guard !videoURL.isEmpty, !videoTitle.isEmpty else { return }
        
        isDownloading = true
        
        do {
            _ = try await networkManager.downloadVideo(from: videoURL, title: videoTitle)
            
            await MainActor.run {
                // Clear form
                videoURL = ""
                videoTitle = ""
                
                // Switch to downloads view
                selectedSection = networkManager.sections.first(where: { $0.id == "my_downloads" })
                _ = networkManager.loadLocalDownloads()
                
                isDownloading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isDownloading = false
            }
        }
    }
}

// MARK: - Wallpaper Grid Item
struct WallpaperGridItem: View {
    let wallpaper: Wallpaper
    @State private var thumbnailImage: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            ZStack {
                if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else if isLoading {
                    ProgressView()
                        .frame(height: 140)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 140)
                        .overlay(
                            VStack {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 24))
                                Text("Video")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.white)
                        )
                }
            }
            .cornerRadius(8)
            .onAppear {
                loadThumbnail()
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    
                HStack(spacing: 4) {
                    Text(wallpaper.duration ?? "Local")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if wallpaper.isLocal {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Text("Downloaded")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func loadThumbnail() {
        // For local files, just show a placeholder since we can't generate thumbnails easily
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
}

// MARK: - Wallpaper Preview View
struct WallpaperPreviewView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Preview Player
            VideoPlayerView(player: player, isPlaying: $isPlaying)
                .frame(height: 300)
                .onAppear {
                    setupPlayer()
                }
                .onDisappear {
                    player?.pause()
                }
            
            // Info
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(wallpaper.title)
                        .font(.system(size: 20, weight: .bold))
                    
                    HStack(spacing: 16) {
                        Label(wallpaper.duration ?? "Local", systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Label(wallpaper.resolution ?? "1080p", systemImage: "display")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        setAsDesktopWallpaper()
                    }) {
                        HStack {
                            Image(systemName: "rectangle.on.rectangle")
                            Text("Set as Desktop Wallpaper")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        setAsScreenSaver()
                    }) {
                        HStack {
                            Image(systemName: "tv")
                            Text("Set as Screen Saver")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        setAsLockScreen()
                    }) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Set as Lock Screen")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(24)
            }
            Spacer()
        }
        .frame(width: 500, height: 600)
    }
    
    private func setupPlayer() {
        let newPlayer = AVPlayer(url: wallpaper.videoURL)
        self.player = newPlayer
        isPlaying = true
    }
    
    private func setAsDesktopWallpaper() {
        wallpaperManager.setDesktopWallpaper(url: wallpaper.videoURL, wallpaper: wallpaper)
        dismiss()
    }
    
    private func setAsScreenSaver() {
        wallpaperManager.setScreenSaver(url: wallpaper.videoURL, wallpaper: wallpaper)
        dismiss()
    }
    
    private func setAsLockScreen() {
        let lockScreenManager = LockScreenManager.shared
        lockScreenManager.setLockScreenVideo(url: wallpaper.videoURL, wallpaper: wallpaper)
        dismiss()
    }
}

// MARK: - Video Player View
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer?
    @Binding var isPlaying: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer?.addSublayer(playerLayer)
        
        context.coordinator.playerLayer = playerLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.playerLayer?.frame = nsView.bounds
        
        if isPlaying {
            player?.play()
        } else {
            player?.pause()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var playerLayer: AVPlayerLayer?
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 20) {
                Toggle("Mute wallpaper audio", isOn: $wallpaperManager.isMuted)
                Toggle("Loop wallpapers", isOn: $wallpaperManager.shouldLoop)
                Toggle("Reduce motion", isOn: $wallpaperManager.reduceMotion)
                Toggle("Low power mode", isOn: $wallpaperManager.lowPowerMode)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 24)
            
            Spacer()
        }
        .frame(width: 400, height: 300)
    }
}