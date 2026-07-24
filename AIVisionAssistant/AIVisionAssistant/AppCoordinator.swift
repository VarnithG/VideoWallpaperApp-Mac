import AppKit
import Combine
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    @Published var isProcessing = false
    @Published var lastResponse: String?
    @Published var errorMessage: String?

    private let captureManager = ScreenCaptureManager()
    private lazy var overlayController = OverlayWindowController()

    private init() {}

    func runCapturePipeline() async {
        guard !isProcessing else { return }
        isProcessing = true
        lastResponse = nil
        errorMessage = nil
        overlayController.showLoading()

        do {
            let image = try await captureManager.captureMainDisplay()
            guard let imageData = image.pngData() else {
                throw CaptureError.captureFailed
            }

            let settings = SettingsStore.shared
            let provider = makeProvider(for: settings.provider)
            guard let apiKey = KeychainHelper.load(account: settings.provider.rawValue),
                  !apiKey.isEmpty else {
                throw VisionAPIError.missingAPIKey
            }
            let response = try await provider.analyze(
                imageData: imageData,
                systemPrompt: settings.systemPrompt,
                apiKey: apiKey,
                model: settings.model
            )
            lastResponse = response
            overlayController.present()
        } catch {
            errorMessage = error.localizedDescription
            overlayController.present()
        }
        isProcessing = false
    }
}

private extension CGImage {
    func pngData() -> Data? {
        let rep = NSBitmapImageRep(cgImage: self)
        return rep.representation(using: .png, properties: [:])
    }
}
