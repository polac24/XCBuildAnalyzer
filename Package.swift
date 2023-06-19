// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    // -enable-bare-slash-regex becomes
    .enableUpcomingFeature("BareSlashRegexLiterals"),
]

let package = Package(
    name: "BuildAnalyzer",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuildAnalyzerKit",
            targets: ["BuildAnalyzerKit"]),
        .library(
            name: "GraphKit",
            targets: ["GraphKit"]),
    ],
    targets: [
        .target(
            name: "BuildAnalyzerKit",
            // -enable-bare-slash-regex becomes
            swiftSettings: swiftSettings
        ),
        .target(
            name: "GraphKit"),
        .testTarget(
            name: "BuildAnalyzerKitTests",
            dependencies: ["BuildAnalyzerKit"]),
        .testTarget(
            name: "GraphKitTests",
            dependencies: ["GraphKit"]),
    ]
)
