import ScreenCaptureKit
import CoreGraphics
import AppKit

enum CaptureError: LocalizedError {
    case noDisplay
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .noDisplay:
            return "The main display could not be found."
        case .captureFailed:
            return "The screenshot could not be captured."
        }
    }
}

final class ScreenCaptureManager {
    func captureMainDisplay() async throws -> CGImage {
        let displayID = CGMainDisplayID()
        guard displayID != 0 else { throw CaptureError.noDisplay }

        if #available(macOS 14.0, *) {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: true
            )
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                throw CaptureError.noDisplay
            }

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let configuration = SCStreamConfiguration()
            configuration.width = display.width
            configuration.height = display.height
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            return try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
        }

        guard let image = CGDisplayCreateImage(displayID) else {
            throw CaptureError.captureFailed
        }
        return image
    }
}
