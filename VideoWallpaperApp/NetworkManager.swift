import Foundation
import SwiftSoup
import Combine

// MARK: - Wallpaper Model
struct Wallpaper: Identifiable, Codable {
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

// MARK: - Network Manager
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let baseURL = "https://wallsflow.com"
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Search Wallpapers
    func searchWallpapers(query: String) async throws -> [Wallpaper] {
        isLoading = true
        errorMessage = nil
        
        defer {
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
        
        guard let searchURL = URL(string: "\(baseURL)/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, _) = try await session.data(from: searchURL)
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingFailed
        }
        
        let wallpapers = try parseWallpapers(from: htmlString)
        
        DispatchQueue.main.async {
            self.wallpapers = wallpapers
        }
        
        return wallpapers
    }
    
    // MARK: - Parse HTML with SwiftSoup
    private func parseWallpapers(from html: String) throws -> [Wallpaper] {
        let doc: Document = try SwiftSoup.parse(html)
        var wallpapers: [Wallpaper] = []
        
        // Try multiple selector patterns based on potential HTML structure
        let selectors = [
            "div.video-item",
            "div.wallpaper-item", 
            "article.video",
            "div[class*='video']",
            "div[class*='wallpaper']",
            "a[href*='.mp4']"
        ]
        
        for selector in selectors {
            do {
                let elements = try doc.select(selector)
                
                for element in elements {
                    if let wallpaper = try parseWallpaperElement(element) {
                        wallpapers.append(wallpaper)
                    }
                }
                
                if !wallpapers.isEmpty {
                    break // Found wallpapers with this selector
                }
            } catch {
                continue // Try next selector
            }
        }
        
        // Fallback: Direct MP4 link extraction
        if wallpapers.isEmpty {
            wallpapers = try extractDirectMP4Links(from: doc)
        }
        
        return wallpapers
    }
    
    // MARK: - Parse Individual Wallpaper Element
    private func parseWallpaperElement(_ element: Element) throws -> Wallpaper? {
        // Try to extract thumbnail
        let thumbnailSelector = "img[src]"
        let videoSelector = "a[href*='.mp4'], source[src*='.mp4'], video source"
        
        guard let thumbnailElement = try element.select(thumbnailSelector).first(),
              let thumbnailSrc = try thumbnailElement.attr("src").nilIfEmpty ?? try thumbnailElement.attr("data-src").nilIfEmpty else {
            return nil
        }
        
        // Convert relative URLs to absolute
        let thumbnailURL = URL(string: thumbnailSrc.hasPrefix("http") ? thumbnailSrc : "\(baseURL)\(thumbnailSrc)")
        
        // Try to extract video URL
        var videoURL: URL?
        
        // Try different video URL extraction methods
        if let videoElement = try element.select(videoSelector).first() {
            let videoSrc = try videoElement.attr("src").nilIfEmpty ?? try videoElement.attr("href").nilIfEmpty
            if let videoSrc = videoSrc {
                videoURL = URL(string: videoSrc.hasPrefix("http") ? videoSrc : "\(baseURL)\(videoSrc)")
            }
        }
        
        // Fallback: try to construct video URL from thumbnail
        if videoURL == nil, let thumbnailURL = thumbnailURL {
            videoURL = try constructVideoURL(from: thumbnailURL)
        }
        
        guard let videoURL = videoURL else {
            return nil
        }
        
        // Extract title
        let title = try element.select("h1, h2, h3, .title, .name").first()?.text() ?? "Wallpaper"
        
        // Extract metadata
        let duration = try element.select(".duration, .time").first()?.text()
        let resolution = try element.select(".resolution, .quality").first()?.text()
        
        return Wallpaper(
            title: title,
            thumbnailURL: thumbnailURL,
            videoURL: videoURL,
            duration: duration,
            resolution: resolution
        )
    }
    
    // MARK: - Extract Direct MP4 Links
    private func extractDirectMP4Links(from doc: Document) throws -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        
        let mp4Links = try doc.select("a[href*='.mp4']")
        
        for (index, link) in mp4Links.enumerated() {
            guard let href = try link.attr("href").nilIfEmpty else { continue }
            
            let videoURL = URL(string: href.hasPrefix("http") ? href : "\(baseURL)\(href)")
            let thumbnailURL = videoURL // Fallback: use same URL
            
            let title = try link.text().nilIfEmpty ?? "Wallpaper \(index + 1)"
            
            wallpapers.append(Wallpaper(
                title: title,
                thumbnailURL: thumbnailURL,
                videoURL: videoURL
            ))
        }
        
        return wallpapers
    }
    
    // MARK: - Construct Video URL from Thumbnail
    private func constructVideoURL(from thumbnailURL: URL) throws -> URL {
        let urlString = thumbnailURL.absoluteString
        
        // Common patterns:
        // thumbnail: https://example.com/thumbnails/video1.jpg
        // video: https://example.com/videos/video1.mp4
        
        let replacements = [
            ("/thumbnails/", "/videos/"),
            ("/thumbs/", "/videos/"),
            ("/preview/", "/video/"),
            (".jpg", ".mp4"),
            (".png", ".mp4"),
            (".jpeg", ".mp4"),
            ("_thumb", ""),
            ("_preview", ""),
            ("-thumb", ""),
            ("-preview", "")
        ]
        
        var videoString = urlString
        for (pattern, replacement) in replacements {
            videoString = videoString.replacingOccurrences(of: pattern, with: replacement)
        }
        
        guard let videoURL = URL(string: videoString) else {
            throw NetworkError.invalidURL
        }
        
        return videoURL
    }
    
    // MARK: - Download Video
    func downloadVideo(from url: URL, to destinationURL: URL) async throws -> Progress {
        let progress = Progress(totalUnitCount: 100)
        
        var observation: NSKeyValueObservation?
        
        let task = session.downloadTask(with: url) { tempURL, response, error in
            observation?.invalidate()
            
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let tempURL = tempURL else { return }
            
            do {
                // Create directory if needed
                let directory = destinationURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                
                // Move file to destination
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                
                DispatchQueue.main.async {
                    progress.completedUnitCount = 100
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        observation = task.progress.observe(\.fractionCompleted) { taskProgress in
            DispatchQueue.main.async {
                progress.completedUnitCount = Int64(taskProgress.fractionCompleted * 100)
            }
        }
        
        task.resume()
        
        return progress
    }
    
    // MARK: - Download Thumbnail
    func downloadThumbnail(from url: URL) async throws -> URL {
        let (tempURL, _) = try await session.download(from: url)
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailsPath = documentsPath.appendingPathComponent("VideoWallpaper/Thumbnails")
        
        try FileManager.default.createDirectory(at: thumbnailsPath, withIntermediateDirectories: true)
        
        let destinationURL = thumbnailsPath.appendingPathComponent(url.lastPathComponent)
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        
        return destinationURL
    }
}

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidURL
    case decodingFailed
    case downloadFailed
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

// MARK: - String Extension
extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}