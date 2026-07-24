// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AIVisionAssistant",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "AIVisionAssistant", targets: ["AIVisionAssistant"])
    ],
    targets: [
        .executableTarget(
            name: "AIVisionAssistant",
            path: "AIVisionAssistant",
            sources: [
                "main.swift",
                "AppDelegate.swift",
                "AppCoordinator.swift",
                "HotkeyManager.swift",
                "ScreenCapture/ScreenCaptureManager.swift",
                "API/AIProvider.swift",
                "API/VisionAPIClient.swift",
                "Settings/SettingsStore.swift",
                "Settings/KeychainHelper.swift",
                "Window/PanelController.swift",
                "Window/OverlayWindowController.swift",
                "UI/PanelView.swift",
                "UI/SettingsView.swift",
                "UI/OverlayView.swift"
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("Security"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("Foundation")
            ]
        )
    ]
)
