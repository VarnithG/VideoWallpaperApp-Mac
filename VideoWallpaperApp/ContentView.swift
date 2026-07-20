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
    @State private var selectedSection: WebsiteSection?
    @State private var showingError = false
    @State private var errorMessage: String?
    
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
            // Load trending wallpapers on app launch
            Task {
                await loadTrendingWallpapers()
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
                
                Text("Wallsflow")
                    .font(.system(size: 18, weight: .bold))
            }
            .padding(.vertical, 20)
            
            Divider()
            
            // Sections
            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(networkManager.sections) { section in
                        Button(action: {
                            selectedSection = section
                            Task {
                                await loadSectionWallpapers(section)
                            }
                        }) {
                            HStack(spacing: 12) {
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
            }
            
            Spacer()
            
            // Search in sidebar
            VStack(spacing: 12) {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task {
                            await searchWallpapers()
                        }
                    }
                
                Button(action: {
                    Task {
                        await searchWallpapers()
                    }
                }) {
                    Text("Search")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(width: 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
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
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No wallpapers found")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Select a section from the sidebar or search for wallpapers")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
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
    
    // MARK: - Load Trending Wallpapers
    private func loadTrendingWallpapers() async {
        guard let trendingSection = networkManager.sections.first else { return }
        selectedSection = trendingSection
        
        do {
            _ = try await networkManager.fetchSectionWallpapers(section: trendingSection)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Load Section Wallpapers
    private func loadSectionWallpapers(_ section: WebsiteSection) async {
        do {
            _ = try await networkManager.fetchSectionWallpapers(section: section)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    // MARK: - Search Wallpapers
    private func searchWallpapers() async {
        guard !searchText.isEmpty else { return }
        
        selectedSection = nil
        
        do {
            _ = try await networkManager.searchWallpapers(query: searchText)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
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
                    Text(wallpaper.duration ?? "0:00")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(wallpaper.resolution ?? "720p")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func loadThumbnail() {
        Task {
            do {
                let localURL = try await NetworkManager.shared.downloadThumbnail(from: wallpaper.thumbnailURL)
                
                if let image = NSImage(contentsOf: localURL) {
                    await MainActor.run {
                        self.thumbnailImage = image
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
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
                        Label(wallpaper.duration ?? "0:00", systemImage: "clock")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Label(wallpaper.resolution ?? "720p", systemImage: "display")
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
                    
                    if isDownloading {
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
        
        let directory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let (tempURL, response) = try await URLSession.shared.download(from: wallpaper.videoURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
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