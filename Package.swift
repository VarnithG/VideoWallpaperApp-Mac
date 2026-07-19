// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VideoWallpaperApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VideoWallpaperApp",
            targets: ["VideoWallpaperApp"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "VideoWallpaperApp",
            path: "VideoWallpaperApp",
            sources: [
                "AppDelegate.swift",
                "ContentView.swift", 
                "NetworkManager.swift",
                "WallpaperManager.swift",
                "DesktopWindowController.swift",
                "LockScreenManager.swift",
                "WallpaperHistoryView.swift"
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("UserNotifications")
            ]
        ),
    ]
)