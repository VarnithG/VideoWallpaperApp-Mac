import Foundation
import Combine

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

// MARK: - Network Manager
@MainActor
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
            isLoading = false
        }
        
        // For testing, return sample wallpapers with real video URLs
        let sampleWallpapers = [
            Wallpaper(
                title: "Ocean Waves",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "0:30",
                resolution: "720p"
            ),
            Wallpaper(
                title: "Forest Trees",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "0:45",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "Mountain Sunset",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "1:00",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "City Lights",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "0:25",
                resolution: "720p"
            ),
            Wallpaper(
                title: "Starry Night",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "0:35",
                resolution: "1080p"
            ),
            Wallpaper(
                title: "Abstract Flow",
                thumbnailURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                videoURL: URL(string: "https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4")!,
                duration: "0:40",
                resolution: "720p"
            )
        ]
        
        wallpapers = sampleWallpapers
        
        return sampleWallpapers
    }
    
    // MARK: - Parse HTML with Native Swift String Parsing
    private func parseWallpapers(from html: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        
        // Pattern 1: Look for .mp4 links in href attributes
        let mp4Pattern = #"<a\s+[^>]*href=["']([^"']*\.mp4[^"']*)["'][^>]*>([^<]*)</a>"#
        wallpapers.append(contentsOf: extractMP4Links(from: html, using: mp4Pattern))
        
        // Pattern 2: Look for video source elements
        let sourcePattern = #"<source\s+[^>]*src=["']([^"']*\.mp4[^"']*)["']"#
        wallpapers.append(contentsOf: extractSourceLinks(from: html, using: sourcePattern))
        
        // Pattern 3: Look for img tags and try to construct video URLs
        let imgPattern = #"<img\s+[^>]*src=["']([^"']*)["']"#
        wallpapers.append(contentsOf: extractFromImages(from: html, using: imgPattern))
        
        // Remove duplicates
        let uniqueWallpapers = Array(Set(wallpapers)).prefix(20)
        
        return Array(uniqueWallpapers)
    }
    
    // MARK: - Extract MP4 Links from Anchor Tags
    private func extractMP4Links(from html: String, using pattern: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match = match,
                  match.numberOfRanges >= 3,
                  let hrefRange = Range(match.range(at: 1), in: html),
                  let textRange = Range(match.range(at: 2), in: html) else {
                return
            }
            
            let hrefString = String(html[hrefRange])
            let textString = String(html[textRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let videoURL = URL(string: hrefString.hasPrefix("http") ? hrefString : "\(baseURL)\(hrefString)")
            let thumbnailURL = videoURL // Fallback
            
            let title = textString.isEmpty ? "Video Wallpaper" : textString
            
            wallpapers.append(Wallpaper(
                title: title,
                thumbnailURL: thumbnailURL ?? URL(string: baseURL)!,
                videoURL: videoURL ?? URL(string: baseURL)!
            ))
        }
        
        return wallpapers
    }
    
    // MARK: - Extract Source Links
    private func extractSourceLinks(from html: String, using pattern: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match = match,
                  match.numberOfRanges >= 2,
                  let srcRange = Range(match.range(at: 1), in: html) else {
                return
            }
            
            let srcString = String(html[srcRange])
            let videoURL = URL(string: srcString.hasPrefix("http") ? srcString : "\(baseURL)\(srcString)")
            let thumbnailURL = videoURL
            
            wallpapers.append(Wallpaper(
                title: "Video Wallpaper",
                thumbnailURL: thumbnailURL ?? URL(string: baseURL)!,
                videoURL: videoURL ?? URL(string: baseURL)!
            ))
        }
        
        return wallpapers
    }
    
    // MARK: - Extract from Images and Construct Video URLs
    private func extractFromImages(from html: String, using pattern: String) -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        
        regex?.enumerateMatches(in: html, options: [], range: range) { match, _, _ in
            guard let match = match,
                  match.numberOfRanges >= 2,
                  let srcRange = Range(match.range(at: 1), in: html) else {
                return
            }
            
            let srcString = String(html[srcRange])
            let thumbnailURL = URL(string: srcString.hasPrefix("http") ? srcString : "\(baseURL)\(srcString)")
            
            // Try to construct video URL from thumbnail
            if let videoURL = self.constructVideoURL(from: thumbnailURL ?? URL(string: baseURL)!) {
                wallpapers.append(Wallpaper(
                    title: "Video Wallpaper",
                    thumbnailURL: thumbnailURL ?? URL(string: baseURL)!,
                    videoURL: videoURL
                ))
            }
        }
        
        return wallpapers
    }
    
    // MARK: - Construct Video URL from Thumbnail
    private func constructVideoURL(from thumbnailURL: URL) -> URL? {
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
            (".webp", ".mp4"),
            ("_thumb", ""),
            ("_preview", ""),
            ("-thumb", ""),
            ("-preview", "")
        ]
        
        var videoString = urlString
        for (pattern, replacement) in replacements {
            videoString = videoString.replacingOccurrences(of: pattern, with: replacement)
        }
        
        return URL(string: videoString)
    }
    
    // MARK: - Download Video
    func downloadVideo(from url: URL, to destinationURL: URL) async throws -> Progress {
        let progress = Progress(totalUnitCount: 100)
        
        var observation: NSKeyValueObservation?
        
        let task = session.downloadTask(with: url) { [weak self] tempURL, response, error in
            observation?.invalidate()
            
            guard let self = self else { return }
            
            if let error = error {
                Task { @MainActor in
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
                
                Task { @MainActor in
                    progress.completedUnitCount = 100
                }
            } catch {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                }
            }
        }
        
        observation = task.progress.observe(\.fractionCompleted) { taskProgress, _ in
            Task { @MainActor in
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