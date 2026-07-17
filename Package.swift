// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoWallpaperApp",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0")
    ],
    targets: [
        // Note: This is primarily an Xcode project. 
        // Package.swift is used for dependency management only.
        // Build the main app using Xcode instead.
    ]
)