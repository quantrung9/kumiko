// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Kumiko",
    platforms: [
        .macOS(.v13)
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
        // OpenCV binary framework for macOS
        .package(
            url: "https://github.com/yeatse/opencv-spm.git",
            from: "4.10.0"
        ),
    ],
    targets: [
        // C++ bridge for OpenCV with Swift interop
        // Provides Swift-friendly wrappers around OpenCV functions
        .target(
            name: "OpenCVBridge",
            dependencies: [
                .product(name: "opencv2", package: "opencv-spm")
            ],
            path: "Sources/OpenCVBridge",
            sources: ["OpenCVBridge.cpp"],
            publicHeadersPath: "include",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        // Main library target
        .target(
            name: "Kumiko",
            dependencies: ["OpenCVBridge"],
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
    ],
    cxxLanguageStandard: .cxx14
)
