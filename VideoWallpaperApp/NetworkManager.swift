import Foundation
import Combine

// MARK: - Network Error
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case decodingFailed
    case noResultsFound
    case connectionError
    
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
        case .connectionError:
            return "Failed to connect to server"
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
        
        let urlString = "https://wallsflow.com\(section.url)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.connectionError
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingFailed
            }
            
            print("Fetched \(htmlString.count) characters from \(urlString)")
            
            let wallpapers = parseWallpapersFromHTML(htmlString)
            
            if wallpapers.isEmpty {
                // Fallback to sample wallpapers if parsing fails
                print("No wallpapers parsed, using fallback")
                return getSampleWallpapers()
            }
            
            self.wallpapers = wallpapers
            print("Parsed \(wallpapers.count) wallpapers")
            
            return wallpapers
            
        } catch {
            print("Error fetching wallpapers: \(error)")
            // Fallback to sample wallpapers on error
            return getSampleWallpapers()
        }
    }
    
    // MARK: - Search Wallpapers
    func searchWallpapers(query: String) async throws -> [Wallpaper] {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let urlString = "https://wallsflow.com/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.connectionError
            }
            
            guard let htmlString = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingFailed
            }
            
            let wallpapers = parseWallpapersFromHTML(htmlString)
            
            if wallpapers.isEmpty {
                return getSampleWallpapers()
            }
            
            self.wallpapers = wallpapers
            return wallpapers
            
        } catch {
            print("Error searching wallpapers: \(error)")
            return getSampleWallpapers()
        }
    }
    
    // MARK: - Parse Wallpapers from HTML
    private func parseWallpapersFromHTML(_ html: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        
        // Look for various video URL patterns
        let patterns = [
            #"https?://[^\s"']+\.mp4"#,
            #"https?://[^\s"']+\.webm"#,
            #"https?://[^\s"']+\.mov"#
        ]
        
        var usedURLs = Set<String>()
        
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
                continue
            }
            
            let range = NSRange(html.startIndex..<html.endIndex, in: html)
            let matches = regex.matches(in: html, options: [], range: range)
            
            for match in matches {
                guard let urlRange = Range(match.range, in: html) else { continue }
                let urlString = String(html[urlRange])
                
                // Avoid duplicates
                if usedURLs.contains(urlString) { continue }
                usedURLs.insert(urlString)
                
                guard let videoURL = URL(string: urlString) else { continue }
                
                // Use video URL as thumbnail for now
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
                
                // Limit results
                if wallpapers.count >= 12 { break }
            }
            
            if wallpapers.count >= 12 { break }
        }
        
        return wallpapers
    }
    
    // MARK: - Get Sample Wallpapers (Fallback)
    private func getSampleWallpapers() -> [Wallpaper] {
        let sampleWallpapers = [
            Wallpaper(
                title: "Ocean Waves",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                duration: "0:30",
                resolution: "720p"
            ),
            Wallpaper(
                title: "Mountain View",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!,
                duration: "0:45",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "Forest Scene",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!,
                duration: "1:00",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "City Lights",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!,
                duration: "0:25",
                resolution: "720p"
            ),
            Wallpaper(
                title: "Starry Night",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!,
                duration: "0:35",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "Abstract Flow",
                thumbnailURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4")!,
                duration: "0:40",
                resolution: "720p"
            )
        ]
        
        self.wallpapers = sampleWallpapers
        return sampleWallpapers
    }
    
    // MARK: - Generate Title from URL
    private func generateTitle(from url: String) -> String {
        let components = url.components(separatedBy: "/")
        if let filename = components.last {
            let name = filename.replacingOccurrences(of: ".mp4", with: "")
                .replacingOccurrences(of: ".webm", with: "")
                .replacingOccurrences(of: ".mov", with: "")
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
}