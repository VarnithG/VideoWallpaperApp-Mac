// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VideoWallpaperApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        // Note: This is primarily an Xcode project. 
        // Package.swift is minimal since we removed external dependencies.
        // Build the main app using Xcode instead.
    ]
)