// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoWallpaperApp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VideoWallpaperApp",
            targets: ["VideoWallpaperApp"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        .target(
            name: "VideoWallpaperApp",
            dependencies: ["SwiftSoup"]
        ),
    ]
)