import SwiftUI

// MARK: - Wallpaper History View
struct WallpaperHistoryView: View {
    @StateObject private var wallpaperManager = WallpaperManager.shared
    @State private var history: [Wallpaper] = []
    @State private var showingPreview = false
    @State private var selectedWallpaper: Wallpaper?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Past Wallpapers")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Text("Your previously used wallpapers")
                        .font(.system(size: 14, weight: .regular, design: .default))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    wallpaperManager.resetAll()
                    history = []
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Clear History")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            if history.isEmpty {
                emptyStateView
            } else {
                historyGrid
            }
        }
        .onAppear {
            loadHistory()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Wallpaper History")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Wallpapers you use will appear here")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - History Grid
    private var historyGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 300), spacing: 16)
            ], spacing: 16) {
                ForEach(history) { wallpaper in
                    HistoryWallpaperCard(wallpaper: wallpaper)
                        .onTapGesture {
                            selectedWallpaper = wallpaper
                            showingPreview = true
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Load History
    private func loadHistory() {
        history = wallpaperManager.getDownloadedWallpapers()
    }
}

// MARK: - History Wallpaper Card
struct HistoryWallpaperCard: View {
    let wallpaper: Wallpaper
    @State private var thumbnailImage: NSImage?
    @State private var isLoading = true
    @StateObject private var wallpaperManager = WallpaperManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            ZStack {
                if let image = thumbnailImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 140)
                        .clipped()
                } else if isLoading {
                    Rectangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 140)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                } else {
                    Rectangle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(height: 140)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        )
                }
                
                // Active indicator
                if wallpaperManager.currentWallpaper?.id == wallpaper.id {
                    VStack {
                        HStack {
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                
                                Text("Active")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                        }
                        .padding(12)
                        
                        Spacer()
                    }
                }
            }
            .cornerRadius(12)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(wallpaper.id.prefix(8))
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            // Actions
            HStack(spacing: 8) {
                Button(action: {
                    setAsDesktop()
                }) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                        Text("Desktop")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    deleteWallpaper()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        // For local files, just show a placeholder
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isLoading = false
        }
    }
    
    private func setAsDesktop() {
        let videoPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoWallpaper/Videos/\(wallpaper.id).mp4")
        
        wallpaperManager.setDesktopWallpaper(url: videoPath, wallpaper: wallpaper)
    }
    
    private func deleteWallpaper() {
        let videoPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("VideoWallpaper/Videos/\(wallpaper.id).mp4")
        
        try? FileManager.default.removeItem(at: videoPath)
    }
}