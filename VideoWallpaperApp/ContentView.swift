import SwiftUI
import AVFoundation
import Cocoa
import Foundation

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var networkManager = NetworkManager.shared
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    @State private var searchText = ""
    @State private var selectedWallpaper: Wallpaper?
    @State private var showingPreview = false
    @State private var showingSettings = false
    @State private var downloadedWallpapers: [Wallpaper] = []
    @State private var selectedTab: AppTab = .gallery
    @State private var errorMessage: String?
    
    private let gridItemLayout = [
        GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
    ]
    
    enum AppTab: String, CaseIterable {
        case gallery = "Gallery"
        case history = "History"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Tab Bar
            tabBarView
            
            // Content
            Group {
                switch selectedTab {
                case .gallery:
                    galleryView
                case .history:
                    WallpaperHistoryView()
                }
            }
        }
        .onAppear {
            // Load wallpapers on app launch
            Task {
                await loadSampleWallpapers()
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .help("Quit App")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $selectedWallpaper) { wallpaper in
            WallpaperPreviewView(wallpaper: wallpaper)
        }
        .onAppear {
            loadDownloadedWallpapers()
        }
    }
    
    // MARK: - Tab Bar View
    private var tabBarView: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: tab == .gallery ? "photo.on.rectangle.angled" : "clock.arrow.circlepath")
                            .font(.system(size: 18))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
    
    // MARK: - Gallery View
    private var galleryView: some View {
        VStack(spacing: 0) {
            // Search Bar
            searchBarView
            
            // Content
            if networkManager.isLoading {
                loadingView
            } else if networkManager.wallpapers.isEmpty {
                emptyStateView
            } else {
                wallpaperGridView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Video Wallpaper")
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text("Beautiful live wallpapers for your Mac")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active wallpaper indicator
            if wallpaperManager.currentWallpaper != nil {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search wallpapers...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .onSubmit {
                        Task {
                            await searchWallpapers()
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            await loadSampleWallpapers()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Button(action: {
                Task {
                    await searchWallpapers()
                }
            }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .disabled(searchText.isEmpty || networkManager.isLoading)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching for wallpapers...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("Find Your Perfect Wallpaper")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Search for live wallpapers from Wallsflow")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            if !downloadedWallpapers.isEmpty {
                Divider()
                    .padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Downloads")
                        .font(.system(size: 16, weight: .semibold))
                    
                    ScrollView {
                        LazyVGrid(columns: gridItemLayout, spacing: 16) {
                            ForEach(downloadedWallpapers) { wallpaper in
                                WallpaperGridItem(wallpaper: wallpaper)
                                    .onTapGesture {
                                        selectedWallpaper = wallpaper
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No wallpapers found")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Try a different search term")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Wallpaper Grid View
    private var wallpaperGridView: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 16) {
                ForEach(networkManager.wallpapers) { wallpaper in
                    WallpaperGridItem(wallpaper: wallpaper)
                        .onTapGesture {
                            selectedWallpaper = wallpaper
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Search Wallpapers
    private func searchWallpapers() async {
        guard !searchText.isEmpty else { return }
        
        do {
            _ = try await networkManager.searchWallpapers(query: searchText)
        } catch {
            networkManager.errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Load Sample Wallpapers
    private func loadSampleWallpapers() async {
        do {
            _ = try await networkManager.searchWallpapers(query: "nature")
        } catch {
            print("Error loading sample wallpapers: \(error)")
        }
    }
    
    // MARK: - Load Downloaded Wallpapers
    private func loadDownloadedWallpapers() {
        downloadedWallpapers = wallpaperManager.getDownloadedWallpapers()
    }
}

// MARK: - Wallpaper Grid Item
struct WallpaperGridItem: View {
    let wallpaper: Wallpaper
    @State private var thumbnailImage: NSImage?
    @State private var isLoading = true
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail - using video preview
            ZStack {
                if let player = player {
                    VideoPlayerView(player: player, isPlaying: .constant(true))
                        .frame(height: 140)
                        .cornerRadius(8)
                } else if isLoading {
                    ProgressView()
                        .frame(height: 140)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 140)
                        .overlay(
                            VStack {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 24))
                                Text("Video")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(.secondary)
                        )
                }
            }
            .clipped()
            .onAppear {
                loadVideoPreview()
            }
            .onDisappear {
                player?.pause()
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let duration = wallpaper.duration {
                        Text(duration)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    if let resolution = wallpaper.resolution {
                        Text("•")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                        
                        Text(resolution)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            loadVideoPreview()
        }
    }
    
    private func loadVideoPreview() {
        // Create a muted player for thumbnail preview
        let newPlayer = AVPlayer(url: wallpaper.videoURL)
        newPlayer.isMuted = true
        newPlayer.volume = 0
        
        // Set to loop for preview
        newPlayer.actionAtItemEnd = .none
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.player = newPlayer
            self.player?.play()
            self.isLoading = false
        }
    }
}

// MARK: - Wallpaper Preview View
struct WallpaperPreviewView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) private var dismiss
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
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
                        if let duration = wallpaper.duration {
                            Label(duration, systemImage: "clock")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        
                        if let resolution = wallpaper.resolution {
                            Label(resolution, systemImage: "video")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Divider()
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        setAsDesktopWallpaper()
                    }) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                            Text("Set as Desktop Wallpaper")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(isDownloading)
                    
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
                    .disabled(isDownloading)
                    
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
                    .disabled(isDownloading)
                }
                
                if isDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        
                        Text("Downloading... \(Int(downloadProgress * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
            }
            .padding(24)
            
            Spacer()
        }
        .frame(width: 500, height: 600)
    }
    
    private func setupPlayer() {
        // Create player with the wallpaper's video URL
        let newPlayer = AVPlayer(url: wallpaper.videoURL)
        self.player = newPlayer
        isPlaying = true
    }
    
    private func setAsDesktopWallpaper() {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                let localURL = try await downloadVideo()
                
                await MainActor.run {
                    wallpaperManager.setDesktopWallpaper(url: localURL, wallpaper: wallpaper)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func setAsScreenSaver() {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                let localURL = try await downloadVideo()
                
                await MainActor.run {
                    wallpaperManager.setScreenSaver(url: localURL, wallpaper: wallpaper)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func setAsLockScreen() {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                let localURL = try await downloadVideo()
                
                await MainActor.run {
                    let lockScreenManager = LockScreenManager.shared
                    lockScreenManager.setLockScreenVideo(url: localURL, wallpaper: wallpaper)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    errorMessage = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func downloadVideo() async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("VideoWallpaper/Videos/\(wallpaper.id).mp4")
        
        // Create directory if needed
        let directory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // Download the file directly
        let (tempURL, response) = try await URLSession.shared.download(from: wallpaper.videoURL)
        
        // Check if download was successful
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
        // Move file to destination
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        return destinationURL
    }
}

// MARK: - Video Player View
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer?
    @Binding var isPlaying: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        
        // Create AVPlayerLayer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = view.bounds
        view.layer?.addSublayer(playerLayer)
        
        // Store player layer in context for updates
        context.coordinator.playerLayer = playerLayer
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update frame
        context.coordinator.playerLayer?.frame = nsView.bounds
        
        // Handle play/pause
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
            Text("Settings")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 20)
                .padding(.horizontal, 24)
            
            Divider()
                .padding(.top, 16)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Playback Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Playback")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Toggle("Mute audio", isOn: $wallpaperManager.isMuted)
                        Toggle("Loop playback", isOn: $wallpaperManager.shouldLoop)
                    }
                    .padding(.horizontal, 24)
                    
                    Divider()
                    
                    // Performance Settings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Toggle("Reduce motion", isOn: $wallpaperManager.reduceMotion)
                        Toggle("Low power mode", isOn: $wallpaperManager.lowPowerMode)
                    }
                    .padding(.horizontal, 24)
                    
                    Divider()
                    
                    // Storage
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Storage")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Button("Clear Cache") {
                            wallpaperManager.clearCache()
                        }
                        .buttonStyle(.plain)
                        
                        Button("Reset All Wallpapers") {
                            wallpaperManager.resetAll()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
            }
            
            Divider()
            
            Button("Close") {
                dismiss()
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .frame(width: 400, height: 400)
    }
}
