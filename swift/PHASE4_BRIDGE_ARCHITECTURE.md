# OpenCV Bridge Architecture - Detailed Design

## Overview

This document specifies the complete architecture for the OpenCV C++ bridge layer, which will provide Swift-friendly wrappers around OpenCV functionality needed by Kumiko.

---

## Design Principles

1. **Minimal Surface Area** - Only expose what Kumiko needs
2. **Swift-Friendly Types** - Use simple C++ types compatible with Swift interop
3. **Error Handling** - Return optional types for operations that can fail
4. **Performance** - Minimize copying, use references where safe
5. **Type Safety** - Leverage Swift's type system at the boundary

---

## Module Architecture

### Three-Layer Design

```
┌─────────────────────────────────────────┐
│         Kumiko (Pure Swift)             │
│  - Panel.swift                          │
│  - Page.swift (future)                  │
│  - Image processing logic               │
└────────────┬────────────────────────────┘
             │ Swift API calls
             ▼
┌─────────────────────────────────────────┐
│    OpenCVBridge (C++ with Swift interop)│
│  - Simple structs (Rect, Point, Size)   │
│  - Function wrappers                    │
│  - Type conversions                     │
└────────────┬────────────────────────────┘
             │ C++ API calls
             ▼
┌─────────────────────────────────────────┐
│      COpenCV (System Library)           │
│  - opencv_core                          │
│  - opencv_imgproc                       │
│  - opencv_imgcodecs                     │
└─────────────────────────────────────────┘
```

---

## Layer 1: COpenCV (System Library Target)

### Purpose
Link to system-installed OpenCV via pkg-config

### Package.swift Configuration

```swift
.systemLibrary(
    name: "COpenCV",
    path: "Sources/COpenCV",
    pkgConfig: "opencv4",
    providers: [
        .apt(["libopencv-dev"]),
        .brew(["opencv"])
    ]
)
```

### File Structure

```
Sources/COpenCV/
├── module.modulemap       # Clang module definition
└── opencv4.pc            # pkg-config metadata (optional, for reference)
```

### module.modulemap

```c
module COpenCV [system] {
    // Core OpenCV headers
    header "/usr/local/include/opencv4/opencv2/core.hpp"
    header "/usr/local/include/opencv4/opencv2/imgproc.hpp"
    header "/usr/local/include/opencv4/opencv2/imgcodecs.hpp"

    // Export all symbols
    export *

    // Link required libraries
    link "opencv_core"
    link "opencv_imgproc"
    link "opencv_imgcodecs"
}
```

**Platform-Specific Paths:**
- macOS (Homebrew): `/usr/local/include/opencv4/`
- macOS (Apple Silicon): `/opt/homebrew/include/opencv4/`
- Linux (Ubuntu): `/usr/include/opencv4/`

**Note:** May need conditional compilation or multiple module maps for cross-platform support.

---

## Layer 2: OpenCVBridge (C++ Wrapper with Swift Interop)

### Purpose
Provide Swift-friendly C++ API for OpenCV operations

### Package.swift Configuration

```swift
.target(
    name: "OpenCVBridge",
    dependencies: ["COpenCV"],
    path: "Sources/OpenCVBridge",
    sources: ["OpenCVBridge.cpp"],
    publicHeadersPath: "include",
    cxxSettings: [
        .headerSearchPath("/usr/local/include/opencv4"),
        .headerSearchPath("/opt/homebrew/include/opencv4"),
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
)
```

### File Structure

```
Sources/OpenCVBridge/
├── include/
│   └── OpenCVBridge.h        # Public C++ API
├── OpenCVBridge.cpp          # Implementation
└── OpenCVTypes.h             # Type definitions (optional)
```

---

## OpenCV Bridge API Specification

### Core Types

```cpp
// OpenCVBridge.h
#pragma once

#include <vector>
#include <cstdint>

namespace OpenCVBridge {

// ============================================================================
// MARK: - Basic Geometric Types
// ============================================================================

/// 2D Point with integer coordinates
struct Point {
    int32_t x;
    int32_t y;

    Point() : x(0), y(0) {}
    Point(int32_t x_, int32_t y_) : x(x_), y(y_) {}
};

/// 2D Size with integer dimensions
struct Size {
    int32_t width;
    int32_t height;

    Size() : width(0), height(0) {}
    Size(int32_t w, int32_t h) : width(w), height(h) {}
};

/// Rectangle defined by top-left corner and size
struct Rect {
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;

    Rect() : x(0), y(0), width(0), height(0) {}
    Rect(int32_t x_, int32_t y_, int32_t w, int32_t h)
        : x(x_), y(y_), width(w), height(h) {}

    // Convenience methods
    int32_t right() const { return x + width; }
    int32_t bottom() const { return y + height; }
    int32_t area() const { return width * height; }
};

/// Result type for operations that can fail
template<typename T>
struct Result {
    bool success;
    T value;

    Result() : success(false), value() {}
    Result(const T& val) : success(true), value(val) {}

    static Result failure() {
        Result r;
        r.success = false;
        return r;
    }
};

// ============================================================================
// MARK: - Phase 4 Required Functions
// ============================================================================

/// Calculate bounding rectangle from a polygon (contour)
///
/// Phase 4 requirement: Replace Panel polygon stub
/// Python equivalent: cv2.boundingRect(contour)
///
/// @param points Vector of 2D points forming the polygon
/// @return Bounding rectangle, or failure if points is empty
Result<Rect> boundingRectFromPoints(const std::vector<Point>& points);

// ============================================================================
// MARK: - Future Phase Functions (Phase 5+)
// ============================================================================

/// Image loading and basic operations (Phase 5)
// Result<ImageData> loadImage(const char* path);
// bool saveImage(const char* path, const ImageData& image);

/// Contour detection (Phase 5)
// std::vector<std::vector<Point>> findContours(const ImageData& image);

/// Morphological operations (Phase 5)
// ImageData dilate(const ImageData& image, Size kernelSize);
// ImageData erode(const ImageData& image, Size kernelSize);

} // namespace OpenCVBridge
```

---

### Implementation

```cpp
// OpenCVBridge.cpp
#include "OpenCVBridge.h"
#include <opencv2/opencv.hpp>

namespace OpenCVBridge {

// ============================================================================
// MARK: - Helper Functions
// ============================================================================

/// Convert OpenCVBridge::Point to cv::Point
static cv::Point toCvPoint(const Point& p) {
    return cv::Point(p.x, p.y);
}

/// Convert cv::Point to OpenCVBridge::Point
static Point fromCvPoint(const cv::Point& p) {
    return Point(p.x, p.y);
}

/// Convert cv::Rect to OpenCVBridge::Rect
static Rect fromCvRect(const cv::Rect& r) {
    return Rect(r.x, r.y, r.width, r.height);
}

// ============================================================================
// MARK: - Public API Implementation
// ============================================================================

Result<Rect> boundingRectFromPoints(const std::vector<Point>& points) {
    // Validate input
    if (points.empty()) {
        return Result<Rect>::failure();
    }

    try {
        // Convert to OpenCV points
        std::vector<cv::Point> cvPoints;
        cvPoints.reserve(points.size());

        for (const auto& p : points) {
            cvPoints.push_back(toCvPoint(p));
        }

        // Call OpenCV function
        cv::Rect cvRect = cv::boundingRect(cvPoints);

        // Convert back to our type
        Rect result = fromCvRect(cvRect);

        return Result<Rect>(result);
    } catch (const cv::Exception& e) {
        // OpenCV error occurred
        return Result<Rect>::failure();
    } catch (...) {
        // Unknown error
        return Result<Rect>::failure();
    }
}

} // namespace OpenCVBridge
```

---

## Layer 3: Swift Integration (Kumiko Module)

### Swift Usage Examples

```swift
// Panel.swift
import OpenCVBridge

extension Panel {
    /// Calculate bounding rect from polygon using OpenCV
    private static func boundingRectFromPolygon(_ polygon: [[Int]]) -> (Int, Int, Int, Int)? {
        // Convert Swift [[Int]] to std::vector<Point>
        var points = std.vector<OpenCVBridge.Point>()

        for coord in polygon {
            guard coord.count >= 2 else { continue }
            let point = OpenCVBridge.Point(x: Int32(coord[0]), y: Int32(coord[1]))
            points.push_back(point)
        }

        // Call C++ bridge function
        let result = OpenCVBridge.boundingRectFromPoints(points)

        // Check if successful
        guard result.success else {
            return nil
        }

        let rect = result.value
        return (Int(rect.x), Int(rect.y), Int(rect.width), Int(rect.height))
    }

    /// Initialize panel from polygon using OpenCV bounding rect
    public convenience init(page: PanelPage, polygon: [[Int]], splittable: Bool = true) {
        if let (x, y, w, h) = Panel.boundingRectFromPolygon(polygon) {
            self.init(page: page, xywh: [x, y, w, h], polygon: polygon, splittable: splittable)
        } else {
            // Fallback to simplified calculation
            let minX = polygon.map { $0[0] }.min() ?? 0
            let minY = polygon.map { $0[1] }.min() ?? 0
            let maxX = polygon.map { $0[0] }.max() ?? 0
            let maxY = polygon.map { $0[1] }.max() ?? 0
            let width = maxX - minX
            let height = maxY - minY

            self.init(page: page, xywh: [minX, minY, width, height], polygon: polygon, splittable: splittable)
        }
    }
}
```

---

## Type Mapping Reference

### C++ to Swift Type Conversions

| C++ Type | Swift Type | Notes |
|----------|-----------|-------|
| `int32_t` | `Int32` | Guaranteed size across platforms |
| `bool` | `Bool` | Direct mapping |
| `std::vector<T>` | `std.vector<T>` | Swift stdlib C++ types |
| `OpenCVBridge::Point` | `OpenCVBridge.Point` | Namespace becomes module |
| `OpenCVBridge::Rect` | `OpenCVBridge.Rect` | Swift struct |
| `Result<T>` | `OpenCVBridge.Result<T>` | Generic template |
| `const char*` | `UnsafePointer<CChar>` | For strings (Phase 5+) |

### Safe Patterns

✅ **DO:**
- Use simple structs with POD (Plain Old Data) types
- Return `Result<T>` for failable operations
- Use `int32_t` instead of `int` for platform consistency
- Catch all exceptions in C++ layer

❌ **DON'T:**
- Expose `cv::Mat` directly (complex type)
- Use C++ exceptions across Swift boundary
- Return raw pointers
- Use C++ virtual methods in exposed types

---

## Error Handling Strategy

### C++ Layer (OpenCVBridge)

```cpp
Result<Rect> boundingRectFromPoints(const std::vector<Point>& points) {
    // 1. Validate preconditions
    if (points.empty()) {
        return Result<Rect>::failure();
    }

    // 2. Wrap in try-catch
    try {
        // ... OpenCV operations ...
        return Result<Rect>(result);
    } catch (const cv::Exception& e) {
        // Log OpenCV errors (Phase 7: debug mode)
        return Result<Rect>::failure();
    } catch (...) {
        return Result<Rect>::failure();
    }
}
```

### Swift Layer (Kumiko)

```swift
let result = OpenCVBridge.boundingRectFromPoints(points)

guard result.success else {
    // Handle failure - use fallback or throw Swift error
    return nil
}

let rect = result.value
// Use rect...
```

---

## Build Configuration

### Platform-Specific Headers

**Option 1: Environment Variable**
```bash
# macOS Intel
export OPENCV_INCLUDE_PATH=/usr/local/include/opencv4

# macOS Apple Silicon
export OPENCV_INCLUDE_PATH=/opt/homebrew/include/opencv4

# Linux
export OPENCV_INCLUDE_PATH=/usr/include/opencv4
```

**Option 2: Multiple Module Maps**
```
Sources/COpenCV/
├── module.modulemap.macos-intel
├── module.modulemap.macos-arm
├── module.modulemap.linux
└── module.modulemap -> (symlink to appropriate one)
```

**Option 3: Script-Generated (Recommended)**
```bash
# generate-modulemap.sh
#!/bin/bash

OPENCV_PATH=$(pkg-config --variable=includedir opencv4)

cat > Sources/COpenCV/module.modulemap <<EOF
module COpenCV [system] {
    header "$OPENCV_PATH/opencv2/core.hpp"
    header "$OPENCV_PATH/opencv2/imgproc.hpp"
    header "$OPENCV_PATH/opencv2/imgcodecs.hpp"
    export *
    link "opencv_core"
    link "opencv_imgproc"
    link "opencv_imgcodecs"
}
EOF
```

---

## Testing Strategy

### Unit Tests for OpenCVBridge

```swift
// Tests/KumikoTests/OpenCVBridgeTests.swift
import XCTest
@testable import OpenCVBridge

final class OpenCVBridgeTests: XCTestCase {

    func testBoundingRectFromPoints() {
        // Create test points forming a rectangle
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 10, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 170))
        points.push_back(OpenCVBridge.Point(x: 10, y: 170))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 10)
        XCTAssertEqual(result.value.y, 20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 150)
    }

    func testBoundingRectEmptyPoints() {
        let points = std.vector<OpenCVBridge.Point>()
        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertFalse(result.success)
    }

    func testBoundingRectIrregularPolygon() {
        // Test with non-rectangular polygon
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 50, y: 0))
        points.push_back(OpenCVBridge.Point(x: 100, y: 50))
        points.push_back(OpenCVBridge.Point(x: 50, y: 100))
        points.push_back(OpenCVBridge.Point(x: 0, y: 50))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 0)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 100)
    }
}
```

### Integration Tests with Panel

```swift
// Tests/KumikoTests/PanelOpenCVTests.swift
import XCTest
@testable import Kumiko

final class PanelOpenCVTests: XCTestCase {

    func testPanelFromPolygon() {
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()

        // Create panel from polygon
        let polygon = [
            [10, 20],
            [110, 20],
            [110, 170],
            [10, 170]
        ]

        let panel = Panel(page: page, polygon: polygon)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
        XCTAssertEqual(panel.w(), 100)
        XCTAssertEqual(panel.h(), 150)
    }
}
```

---

## Performance Considerations

### Memory Management

**Vector Conversions:**
- Reserve capacity upfront: `cvPoints.reserve(points.size())`
- Use move semantics where possible
- Avoid unnecessary copies

**Reference Passing:**
- Use `const&` for input parameters
- Return by value for small types (Rect, Point, Size)
- Use `Result<T>` to avoid exceptions

### Optimization Flags

```swift
// Package.swift - Release configuration
cxxSettings: [
    .define("NDEBUG", .when(configuration: .release)),
    .unsafeFlags(["-O3"], .when(configuration: .release))
]
```

---

## Migration Path for Existing Code

### Current Panel.swift (Stub)

```swift
// Phase 3 stub implementation
private static func boundingRectFromPolygon(_ polygon: [[Int]]) -> (Int, Int, Int, Int) {
    // Simplified bounding box calculation
    let minX = polygon.map { $0[0] }.min() ?? 0
    let minY = polygon.map { $0[1] }.min() ?? 0
    let maxX = polygon.map { $0[0] }.max() ?? 0
    let maxY = polygon.map { $0[1] }.max() ?? 0
    return (minX, minY, maxX - minX, maxY - minY)
}
```

### Phase 4 Implementation

```swift
// Replace with OpenCV version, keep fallback
private static func boundingRectFromPolygon(_ polygon: [[Int]]) -> (Int, Int, Int, Int) {
    #if HAVE_OPENCV
    // Try OpenCV implementation
    if let rect = boundingRectFromPolygonOpenCV(polygon) {
        return rect
    }
    #endif

    // Fallback to simple calculation
    let minX = polygon.map { $0[0] }.min() ?? 0
    let minY = polygon.map { $0[1] }.min() ?? 0
    let maxX = polygon.map { $0[0] }.max() ?? 0
    let maxY = polygon.map { $0[1] }.max() ?? 0
    return (minX, minY, maxX - minX, maxY - minY)
}

#if HAVE_OPENCV
private static func boundingRectFromPolygonOpenCV(_ polygon: [[Int]]) -> (Int, Int, Int, Int)? {
    var points = std.vector<OpenCVBridge.Point>()

    for coord in polygon {
        guard coord.count >= 2 else { continue }
        points.push_back(OpenCVBridge.Point(x: Int32(coord[0]), y: Int32(coord[1])))
    }

    let result = OpenCVBridge.boundingRectFromPoints(points)

    guard result.success else { return nil }

    let rect = result.value
    return (Int(rect.x), Int(rect.y), Int(rect.width), Int(rect.height))
}
#endif
```

---

## Future Expansion (Phase 5+)

### Image Operations

```cpp
// Future API for image loading/processing
namespace OpenCVBridge {

struct ImageData {
    int32_t width;
    int32_t height;
    int32_t channels;
    std::vector<uint8_t> data;
};

Result<ImageData> loadImage(const char* path);
bool saveImage(const char* path, const ImageData& image);
ImageData convertToGrayscale(const ImageData& image);

} // namespace OpenCVBridge
```

### Contour Detection

```cpp
// Future API for contour detection
namespace OpenCVBridge {

struct Contour {
    std::vector<Point> points;
    double area;
    Rect boundingRect;
};

std::vector<Contour> findContours(const ImageData& image);

} // namespace OpenCVBridge
```

---

## Summary Checklist

### Phase 4A: System Library ✅
- [ ] Create `Sources/COpenCV/` directory
- [ ] Write `module.modulemap` with platform-specific paths
- [ ] Add `COpenCV` target to Package.swift
- [ ] Test pkg-config detection
- [ ] Document installation instructions

### Phase 4B: C++ Bridge ✅
- [ ] Create `Sources/OpenCVBridge/include/OpenCVBridge.h`
- [ ] Create `Sources/OpenCVBridge/OpenCVBridge.cpp`
- [ ] Implement `boundingRectFromPoints()`
- [ ] Add `OpenCVBridge` target to Package.swift
- [ ] Enable C++ interop mode
- [ ] Configure linker settings

### Phase 4C: Swift Integration ✅
- [ ] Import `OpenCVBridge` in Panel.swift
- [ ] Replace `boundingRectFromPolygon` stub with OpenCV version
- [ ] Add fallback for when OpenCV unavailable
- [ ] Update Panel initializer to use OpenCV
- [ ] Test Panel creation from polygon

### Phase 4D: Testing & Documentation ✅
- [ ] Create `OpenCVBridgeTests.swift`
- [ ] Create `PanelOpenCVTests.swift`
- [ ] Write installation guide
- [ ] Update README with OpenCV requirements
- [ ] Create PHASE4_CHECKLIST.md
- [ ] Performance benchmarking

---

**Document Version:** 1.0
**Date:** 2024-11-16
**Phase:** 4 (OpenCV Integration)
**Status:** Architecture Design Complete ✅
**Next:** Implementation
