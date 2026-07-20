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
    
    init(id: String = UUID().uuidString, title: String, thumbnailURL: URL, videoURL: URL, duration: String? = nil, resolution: String? = nil) {
        self.id = id
        self.title = title
        self.thumbnailURL = thumbnailURL
        self.videoURL = videoURL
        self.duration = duration
        self.resolution = resolution
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
    private let baseURL = "https://wallsflow.com"
    
    // Local downloads folder
    private var downloadsDirectory: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsPath = documentsPath.appendingPathComponent("VideoWallpaper/Downloads")
        
        try? FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        
        return downloadsPath
    }
    
    // Website sections from wallsflow.com
    let sections: [WebsiteSection] = [
        WebsiteSection(id: "trending", name: "Trending", url: "/trending"),
        WebsiteSection(id: "new", name: "New", url: "/new"),
        WebsiteSection(id: "popular", name: "Popular", url: "/popular"),
        WebsiteSection(id: "4k", name: "4K", url: "/4k"),
        WebsiteSection(id: "anime", name: "Anime", url: "/anime"),
        WebsiteSection(id: "cars", name: "Cars", url: "/cars"),
        WebsiteSection(id: "nature", name: "Nature", url: "/nature"),
        WebsiteSection(id: "abstract", name: "Abstract", url: "/abstract"),
        WebsiteSection(id: "space", name: "Space", url: "/space"),
        WebsiteSection(id: "gaming", name: "Gaming", url: "/gaming"),
        WebsiteSection(id: "cities", name: "Cities", url: "/cities"),
        WebsiteSection(id: "minimal", name: "Minimal", url: "/minimal")
    ]
    
    private init() {}
    
    // MARK: - Fetch Section Wallpapers
    func fetchSectionWallpapers(section: WebsiteSection) async throws -> [Wallpaper] {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let urlString = "\(baseURL)\(section.url)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingFailed
        }
        
        let wallpapers = parseWallpapersFromHTML(htmlString)
        
        if wallpapers.isEmpty {
            throw NetworkError.noResultsFound
        }
        
        self.wallpapers = wallpapers
        
        return wallpapers
    }
    
    // MARK: - Search Wallpapers
    func searchWallpapers(query: String) async throws -> [Wallpaper] {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let urlString = "\(baseURL)/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingFailed
        }
        
        let wallpapers = parseWallpapersFromHTML(htmlString)
        
        if wallpapers.isEmpty {
            throw NetworkError.noResultsFound
        }
        
        self.wallpapers = wallpapers
        
        return wallpapers
    }
    
    // MARK: - Parse Wallpapers from HTML
    private func parseWallpapersFromHTML(_ html: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        
        // Simplified parsing - look for video URLs in the HTML
        // This is a basic implementation that can be enhanced
        
        // Look for .mp4 URLs
        let mp4Pattern = #"https?://[^\s"']+\.mp4"#
        guard let regex = try? NSRegularExpression(pattern: mp4Pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        var usedURLs = Set<String>()
        
        for match in matches {
            guard let urlRange = Range(match.range, in: html) else { continue }
            let urlString = String(html[urlRange])
            
            // Avoid duplicates
            if usedURLs.contains(urlString) { continue }
            usedURLs.insert(urlString)
            
            guard let videoURL = URL(string: urlString) else { continue }
            
            // Create a thumbnail URL (using the same URL for now)
            let thumbnailURL = videoURL
            
            // Generate a title from the URL
            let title = generateTitle(from: urlString)
            
            let wallpaper = Wallpaper(
                title: title,
                thumbnailURL: thumbnailURL,
                videoURL: videoURL,
                duration: nil,
                resolution: nil
            )
            
            wallpapers.append(wallpaper)
            
            // Limit to prevent too many results
            if wallpapers.count >= 12 { break }
        }
        
        return wallpapers
    }
    
    // MARK: - Generate Title from URL
    private func generateTitle(from url: String) -> String {
        // Extract filename from URL and clean it up
        let components = url.components(separatedBy: "/")
        if let filename = components.last {
            let name = filename.replacingOccurrences(of: ".mp4", with: "")
                .replacingOccurrences(of: "_", with: " ")
                .replacingOccurrences(of: "-", with: " ")
            return name.capitalized
        }
        return "Wallpaper"
    }
    
    // MARK: - Download Video
    func downloadVideo(from url: URL, to destinationURL: URL) async throws {
        let (tempURL, response) = try await session.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.downloadFailed
        }
        
        let directory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
    }
    
    // MARK: - Download Thumbnail
    func downloadThumbnail(from url: URL) async throws -> URL {
        let (tempURL, _) = try await session.download(from: url)
        let documentsPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("thumbnails/\(UUID().uuidString).jpg")
        
        let directory = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        return destinationURL
    }
    
    // MARK: - Get Downloads Directory
    func getDownloadsDirectory() -> URL {
        return downloadsDirectory
    }
}