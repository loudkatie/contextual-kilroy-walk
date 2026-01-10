// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ContextualCore",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "ContextualCore",
            targets: ["ContextualCore"]
        ),
    ],
    targets: [
        .target(
            name: "ContextualCore"
        ),
        .testTarget(
            name: "ContextualCoreTests",
            dependencies: ["ContextualCore"]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
