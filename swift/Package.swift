// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kumiko",
    platforms: [
        .macOS(.v13),
        .linux
    ],
    products: [
        // Library product for the Kumiko framework
        .library(
            name: "Kumiko",
            targets: ["Kumiko"]
        ),
        // Executable product for the CLI tool
        .executable(
            name: "kumiko-cli",
            targets: ["kumiko-cli"]
        ),
    ],
    dependencies: [
        // Swift ArgumentParser for CLI argument parsing
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.3.0"
        ),
        // Note: OpenCV integration will be added in Phase 4
        // Options being researched:
        // 1. Community Swift-OpenCV wrappers
        // 2. Manual xcframework integration
        // 3. C++ interop bridge
    ],
    targets: [
        // Main library target
        .target(
            name: "Kumiko",
            dependencies: [],
            path: "Sources/Kumiko"
        ),

        // CLI executable target
        .executableTarget(
            name: "kumiko-cli",
            dependencies: [
                "Kumiko",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/kumiko-cli"
        ),

        // Test target
        .testTarget(
            name: "KumikoTests",
            dependencies: ["Kumiko"],
            path: "Tests/KumikoTests",
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)
