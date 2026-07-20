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
    
    // Website sections similar to wallsflow.com
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
        
        // Parse HTML to extract wallpaper information
        // This is a simplified parser for wallsflow.com structure
        
        // Find all video card elements
        let pattern = #"<a[^>]*href=["']([^"']*)["'][^>]*>.*?<img[^>]*src=["']([^"']*)["'][^>]*>.*?<h3[^>]*>([^<]*)</h3>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)
        
        for match in matches {
            guard match.numberOfRanges >= 4 else { continue }
            
            let hrefRange = Range(match.range(at: 1), in: html)
            let imgRange = Range(match.range(at: 2), in: html)
            let titleRange = Range(match.range(at: 3), in: html)
            
            guard let hrefRange = hrefRange,
                  let imgRange = imgRange,
                  let titleRange = titleRange else { continue }
            
            let href = String(html[hrefRange])
            let imgSrc = String(html[imgRange])
            let title = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Extract video URL from href
            let videoURL = extractVideoURL(from: href)
            let thumbnailURL = URL(string: imgSrc)
            
            if let videoURL = videoURL, let thumbnailURL = thumbnailURL {
                let wallpaper = Wallpaper(
                    title: title,
                    thumbnailURL: thumbnailURL,
                    videoURL: videoURL,
                    duration: nil,
                    resolution: nil
                )
                wallpapers.append(wallpaper)
            }
        }
        
        return wallpapers
    }
    
    // MARK: - Extract Video URL
    private func extractVideoURL(from href: String) -> URL? {
        // This would extract the actual video URL from the href
        // For now, return a placeholder - this needs to be implemented based on actual wallsflow structure
        return URL(string: "\(baseURL)\(href)")
    }
    
    // MARK: - Download Video
    func downloadVideo(from url: URL, to destinationURL: URL) async throws -> Progress {
        let progress = Progress(totalUnitCount: 100)
        
        let task = session.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                progress.completedUnitCount = 0
                return
            }
            
            do {
                let directory = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                progress.completedUnitCount = 100
            } catch {
                progress.completedUnitCount = 0
            }
        }
        
        task.resume()
        
        return progress
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
}