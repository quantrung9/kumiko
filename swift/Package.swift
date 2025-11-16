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
        // Phase 4: OpenCV integration via Swift C++ interop
        // Uses system-installed OpenCV (brew install opencv or apt-get install libopencv-dev)
    ],
    targets: [
        // Phase 4: System library for OpenCV
        // Links to OpenCV installed via package manager (brew/apt-get)
        .systemLibrary(
            name: "COpenCV",
            path: "Sources/COpenCV",
            pkgConfig: "opencv4",
            providers: [
                .apt(["libopencv-dev"]),
                .brew(["opencv"])
            ]
        ),

        // Phase 4: C++ bridge for OpenCV with Swift interop
        // Provides Swift-friendly wrappers around OpenCV functions
        .target(
            name: "OpenCVBridge",
            dependencies: ["COpenCV"],
            path: "Sources/OpenCVBridge",
            sources: ["OpenCVBridge.cpp"],
            publicHeadersPath: "include",
            cxxSettings: [
                .headerSearchPath("/usr/local/include/opencv4"),
                .headerSearchPath("/opt/homebrew/include/opencv4"),
                .headerSearchPath("/usr/include/opencv4"),
                .define("HAVE_OPENCV")
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ],
            linkerSettings: [
                .linkedLibrary("opencv_core"),
                .linkedLibrary("opencv_imgproc"),
                .linkedLibrary("opencv_imgcodecs")
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
    ]
)
