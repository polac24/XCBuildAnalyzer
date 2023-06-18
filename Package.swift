// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildAnalyzer",
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
            name: "BuildAnalyzerKit"),
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
