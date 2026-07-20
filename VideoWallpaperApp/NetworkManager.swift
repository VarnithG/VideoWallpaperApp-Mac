import Foundation
import Combine

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case decodingFailed
    case noResultsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .decodingFailed:
            return "Failed to decode response"
        case .downloadFailed:
            return "Failed to download content"
        case .noResultsFound:
            return "No wallpapers found"
        }
    }
}

// MARK: - Wallpaper Model
struct Wallpaper: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let thumbnailURL: URL
    let videoURL: URL
    let duration: String?
    let resolution: String?
    let isLocal: Bool
    
    init(id: String = UUID().uuidString, title: String, thumbnailURL: URL, videoURL: URL, duration: String? = nil, resolution: String? = nil, isLocal: Bool = false) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.duration = duration
        self.resolution = resolution
        self.isLocal = isLocal
    }
}

// MARK: - Website Section
struct WebsiteSection: Identifiable, Hashable {
    let id: String
    let name: String
    let url: String
    
    init(id: String, name: String, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
}

// MARK: - Network Manager
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    
    // Local downloads folder
    private var downloadsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("VideoWallpaper/Downloads")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        
        return downloadsPath
    }
    
    // Sidebar sections
    let sections: [WebsiteSection] = [
        WebsiteSection(id: "download", name: "Download Video", url: "download"),
        WebsiteSection(id: "my_downloads", name: "My Downloads", url: "my_downloads")
    ]
    
    private init() {}
    
    // MARK: - Download Video from URL
    func downloadVideo(from urlString: String, title: String) async throws -> Wallpaper {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (tempURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
        // Create destination file
        let fileName = "\(title.replacingOccurrences(of: " ", with: "_")).mp4"
        let destinationURL = downloadsDirectory.appendingPathComponent(fileName)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        // Move downloaded file
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        // Create wallpaper object
        let wallpaper = Wallpaper(
            title: title,
            thumbnailURL: destinationURL, // Use video as thumbnail for now
            videoURL: destinationURL,
            duration: nil,
            resolution: nil,
            isLocal: true
        )
        
        return wallpaper
    }
    
    // MARK: - Load Local Downloads
    func loadLocalDownloads() -> [Wallpaper] {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        var localWallpapers: [Wallpaper] = []
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: downloadsDirectory, includingPropertiesForKeys: nil)
            
            for file in files where file.pathExtension == "mp4" {
                let title = file.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
                let wallpaper = Wallpaper(
                    title: title,
                    thumbnailURL: file,
                    videoURL: file,
                    duration: nil,
                    resolution: nil,
                    isLocal: true
                )
                localWallpapers.append(wallpaper)
            }
            
            self.wallpapers = localWallpapers
            
        } catch {
            errorMessage = "Failed to load downloads: \(error.localizedDescription)"
        }
        
        return localWallpapers
    }
    
    // MARK: - Delete Downloaded Wallpaper
    func deleteWallpaper(_ wallpaper: Wallpaper) throws {
        guard wallpaper.isLocal else {
            throw NetworkError.downloadFailed
        }
        
        try FileManager.default.removeItem(at: wallpaper.videoURL)
        
        // Reload downloads
        _ = loadLocalDownloads()
    }
    
    // MARK: - Get Download Directory
    func getDownloadsDirectory() -> URL {
        return downloadsDirectory
    }
}