# Phase 4: OpenCV Integration - Technical Research & Plan

## Executive Summary

This document evaluates approaches for integrating OpenCV with the Kumiko Swift port. Based on comprehensive research, **System Library + Swift 5.9 C++ Interoperability** is recommended as the best cross-platform solution for macOS and Linux.

---

## Requirements Analysis

### Platform Support
- ✅ **macOS 13+** - Primary development platform
- ✅ **Linux (Ubuntu 20.04+)** - Server/deployment platform
- ❌ iOS/visionOS - Not required for Kumiko CLI

### OpenCV Usage in Kumiko
Current needs (from Python implementation):
1. **Polygon bounding rectangles** - `cv2.boundingRect(contour)`
2. **Image loading/processing** - Future phases
3. **Contour operations** - Panel detection algorithms

---

## Integration Approaches Evaluated

### Option 1: Binary Swift Packages (Apple Platforms Only)

**Packages:**
- `yeatse/opencv-spm` - Binary xcframework, auto-updates with OpenCV releases
- `r0ml/OpenCV` - Binary framework with Objective-C++ interop
- `Rightpoint/opencv-swift` - XCFramework with Podspec

**Pros:**
- ✅ Zero manual installation on macOS
- ✅ Easy integration via SPM
- ✅ Automated updates

**Cons:**
- ❌ **macOS/iOS only - NO Linux support**
- ❌ Large binary downloads
- ❌ Limited to framework-included OpenCV modules

**Verdict:** ❌ **Rejected** - Linux support is mandatory for Kumiko

---

### Option 2: System Library with Objective-C++ Wrapper

**Architecture:**
```
Swift → Bridging Header → Objective-C++ (.mm) → OpenCV C++
```

**Configuration:**
```swift
.systemLibrary(
    name: "COpenCV",
    pkgConfig: "opencv4",
    providers: [
        .apt(["libopencv-dev"]),
        .brew(["opencv"])
    ]
)
```

**Pros:**
- ✅ Cross-platform (macOS + Linux)
- ✅ Well-documented approach
- ✅ Proven in production
- ✅ Uses system-installed OpenCV

**Cons:**
- ⚠️ Requires Objective-C++ wrapper files (.mm)
- ⚠️ More complex build configuration
- ⚠️ Bridging header management
- ⚠️ Not using modern Swift features

**Verdict:** ✅ **Viable fallback** - Works but not optimal

---

### Option 3: System Library + Swift 5.9 C++ Interoperability ⭐ RECOMMENDED

**Architecture:**
```
Swift (with C++ interop) → C++ Wrapper → OpenCV C++
```

**Configuration:**
```swift
// Package.swift
.systemLibrary(
    name: "COpenCV",
    pkgConfig: "opencv4",
    providers: [
        .apt(["libopencv-dev"]),
        .brew(["opencv"])
    ]
),
.target(
    name: "OpenCVBridge",
    dependencies: ["COpenCV"],
    swiftSettings: [.interoperabilityMode(.Cxx)]
),
.target(
    name: "Kumiko",
    dependencies: ["OpenCVBridge"]
)
```

**Pros:**
- ✅ **Cross-platform (macOS + Linux)**
- ✅ **Modern Swift 5.9+ feature**
- ✅ No Objective-C++ needed
- ✅ Direct C++ API access from Swift
- ✅ Type-safe with Swift generics
- ✅ Uses system-installed OpenCV
- ✅ Clean separation of concerns

**Cons:**
- ⚠️ Requires Swift 5.9+ (already our target)
- ⚠️ Users must install OpenCV manually
- ⚠️ May need thin C++ wrapper for complex types
- ⚠️ Newer feature, less Stack Overflow examples

**Verdict:** ⭐ **RECOMMENDED** - Best fit for Kumiko's requirements

---

## Recommended Architecture

### Directory Structure
```
swift/
├── Package.swift
├── Sources/
│   ├── COpenCV/                    # System library target
│   │   ├── module.modulemap        # Clang module map
│   │   └── opencv.pc               # pkg-config reference
│   ├── OpenCVBridge/               # C++ wrapper target
│   │   ├── OpenCVBridge.h          # Public C++ API
│   │   └── OpenCVBridge.cpp        # OpenCV wrapper implementations
│   └── Kumiko/                     # Swift library
│       ├── Kumiko.swift
│       ├── Panel.swift
│       └── ... (existing files)
```

### Module Structure

#### 1. COpenCV (System Library Target)
**Purpose:** Link to system-installed OpenCV via pkg-config

**module.modulemap:**
```c
module COpenCV [system] {
    header "/usr/local/include/opencv4/opencv2/opencv.hpp"
    link "opencv_core"
    link "opencv_imgproc"
    link "opencv_imgcodecs"
    export *
}
```

#### 2. OpenCVBridge (C++ Target with Interop)
**Purpose:** Thin Swift-friendly C++ wrapper for OpenCV functions

**OpenCVBridge.h:**
```cpp
#pragma once
#include <opencv2/opencv.hpp>
#include <vector>

namespace OpenCVBridge {
    // Simple C++ struct for bounding rect
    struct BoundingRect {
        int x, y, width, height;
    };

    // Swift-friendly wrapper for cv::boundingRect
    BoundingRect boundingRectFromPoints(const std::vector<cv::Point>& points);

    // Future: Image loading, processing, etc.
}
```

**OpenCVBridge.cpp:**
```cpp
#include "OpenCVBridge.h"

namespace OpenCVBridge {
    BoundingRect boundingRectFromPoints(const std::vector<cv::Point>& points) {
        cv::Rect rect = cv::boundingRect(points);
        return BoundingRect{rect.x, rect.y, rect.width, rect.height};
    }
}
```

#### 3. Kumiko (Swift Target)
**Purpose:** Use OpenCV through C++ interop

**Panel.swift (updated):**
```swift
import OpenCVBridge

extension Panel {
    /// Calculate bounding rect from polygon using OpenCV
    private static func boundingRectFromPolygon(_ polygon: [[Int]]) -> (Int, Int, Int, Int) {
        // Convert Swift array to C++ vector
        var points: [cv.Point] = polygon.map { cv.Point($0[0], $0[1]) }

        // Call C++ wrapper
        let rect = OpenCVBridge.boundingRectFromPoints(points)

        return (rect.x, rect.y, rect.width, rect.height)
    }
}
```

---

## Implementation Plan

### Phase 4A: System Library Setup (Week 1, Days 1-2)

**Tasks:**
1. Create `COpenCV` system library target
2. Write `module.modulemap` for OpenCV headers
3. Add pkg-config configuration
4. Test pkg-config detection on macOS (Homebrew)
5. Document installation instructions for users

**Deliverables:**
- Working system library detection
- Installation guide (README section)

### Phase 4B: C++ Bridge (Week 1, Days 3-4)

**Tasks:**
1. Create `OpenCVBridge` target with C++ interop enabled
2. Implement `BoundingRect` struct
3. Implement `boundingRectFromPoints()` wrapper
4. Add linker settings for OpenCV libraries
5. Write unit tests for C++ bridge

**Deliverables:**
- OpenCVBridge.h/cpp with boundingRect
- C++ bridge tests

### Phase 4C: Swift Integration (Week 1, Day 5)

**Tasks:**
1. Import OpenCVBridge in Kumiko module
2. Replace Panel polygon stub with OpenCV implementation
3. Update Panel tests to use real boundingRect
4. Verify cross-platform compatibility

**Deliverables:**
- Panel.boundingRectFromPolygon() implemented
- Panel tests passing with OpenCV

### Phase 4D: Testing & Documentation (Week 2)

**Tasks:**
1. Integration tests with real polygon data
2. Performance benchmarks
3. Linux testing (if environment available)
4. Update PHASE4_CHECKLIST.md
5. Document OpenCV setup in README

**Deliverables:**
- Comprehensive test coverage
- Updated documentation
- Phase 4 completion

---

## Swift 5.9 C++ Interoperability Details

### Enabling C++ Interop

**In Package.swift:**
```swift
.target(
    name: "OpenCVBridge",
    dependencies: ["COpenCV"],
    swiftSettings: [
        .interoperabilityMode(.Cxx)
    ]
)
```

**Compiler flag:**
```
-cxx-interoperability-mode=default
```

### Type Mappings

| C++ Type | Swift Type | Notes |
|----------|-----------|-------|
| `int` | `Int32` | Direct mapping |
| `std::vector<T>` | `std.vector<T>` | Swift namespace |
| `cv::Point` | `cv.Point` | C++ namespaces → Swift modules |
| `cv::Rect` | `cv.Rect` | Can use directly or wrap |
| `std::string` | `std.string` | Needs conversion to Swift String |

### Limitations

- ❌ Cannot import C++20 modules (using Clang modules instead)
- ❌ Virtual methods on C++ value types not callable
- ⚠️ C++ iterators are unsafe in Swift (avoid or wrap)
- ⚠️ Some template metaprogramming not supported

### Best Practices

1. **Create thin wrappers** - Don't expose complex C++ APIs directly to Swift
2. **Use simple structs** - Avoid virtual methods and inheritance in exposed types
3. **Explicit conversion** - Convert between Swift and C++ types explicitly
4. **Namespace organization** - Keep C++ wrapper in dedicated namespace

---

## Installation Requirements

### macOS

```bash
# Install OpenCV via Homebrew
brew install opencv

# Verify installation
pkg-config --modversion opencv4
# Expected output: 4.x.x

# Check pkg-config paths
pkg-config --cflags opencv4
pkg-config --libs opencv4
```

### Linux (Ubuntu 20.04+)

```bash
# Install OpenCV development libraries
sudo apt-get update
sudo apt-get install libopencv-dev

# Verify installation
pkg-config --modversion opencv4
# Expected output: 4.x.x

# If opencv4.pc not found, may need to install opencv-data
sudo apt-get install opencv-data
```

### Troubleshooting

**Issue:** `Package opencv4 was not found`
**Solution:**
- OpenCV 4.x may not generate .pc files by default
- When building from source, add `-D OPENCV_GENERATE_PKGCONFIG=YES`
- Check if opencv.pc exists instead of opencv4.pc

**Issue:** Headers not found
**Solution:**
- Update module.modulemap header paths
- Common locations:
  - macOS: `/usr/local/include/opencv4/`
  - Linux: `/usr/include/opencv4/`

---

## Risk Assessment

### Low Risk
- ✅ System library approach is proven
- ✅ C++ interop works on all Swift platforms
- ✅ OpenCV is widely available via package managers

### Medium Risk
- ⚠️ Swift C++ interop is relatively new (5.9+)
- ⚠️ Module map configuration can be finicky
- ⚠️ pkg-config paths vary across systems

### Mitigation Strategies
1. **Comprehensive documentation** - Installation guide for both platforms
2. **Fallback to Objective-C++** - If C++ interop issues arise
3. **Version pinning** - Document tested OpenCV versions
4. **CI/CD testing** - Test on both macOS and Linux

---

## Performance Considerations

### Binary Size
- System library approach = minimal binary bloat
- Only links used OpenCV modules
- No embedded frameworks

### Runtime Performance
- **C++ interop overhead:** Minimal (near-native calls)
- **Type conversion:** Only at Swift-C++ boundary
- **OpenCV performance:** Native C++ speed

### Build Time
- System library = faster builds (no framework compilation)
- C++ interop adds slight compilation overhead
- Overall: Better than binary framework approach

---

## Comparison Matrix

| Criteria | Binary Packages | Obj-C++ Wrapper | **C++ Interop** ⭐ |
|----------|----------------|-----------------|-------------------|
| **Cross-platform** | ❌ Apple only | ✅ All platforms | ✅ All platforms |
| **Linux support** | ❌ No | ✅ Yes | ✅ Yes |
| **Modern Swift** | ✅ SPM | ⚠️ Legacy | ✅ Swift 5.9+ |
| **Setup complexity** | ✅ Easy | ⚠️ Medium | ⚠️ Medium |
| **User install required** | ❌ No | ✅ Yes | ✅ Yes |
| **Build speed** | ⚠️ Slow | ✅ Fast | ✅ Fast |
| **Binary size** | ❌ Large | ✅ Small | ✅ Small |
| **Type safety** | ✅ Good | ⚠️ Bridging | ✅ Excellent |
| **Maintenance** | ✅ Auto-update | ⚠️ Manual | ✅ Stable API |
| **Production ready** | ✅ Yes | ✅ Yes | ⚠️ Emerging |

---

## Decision: System Library + C++ Interoperability ⭐

### Rationale

1. **Cross-platform requirement is non-negotiable** - Binary packages fail this
2. **Modern Swift alignment** - Leverages Swift 5.9+ features
3. **Clean architecture** - No Objective-C++ complexity
4. **Reasonable user burden** - CV developers expect OpenCV installation
5. **Future-proof** - C++ interop is Swift's direction for native libraries

### Implementation Confidence: HIGH ✅

- Swift C++ interop is production-ready (shipped in 5.9)
- System library approach is well-documented
- OpenCV C++ API is stable and mature
- Fallback to Objective-C++ if needed

---

## Next Steps

1. ✅ Research complete (this document)
2. 🔄 Design OpenCV bridge architecture (create detailed API spec)
3. ⏳ Implement COpenCV system library target
4. ⏳ Implement OpenCVBridge C++ wrapper
5. ⏳ Integrate with Panel class
6. ⏳ Test on macOS and Linux (if available)
7. ⏳ Document installation and usage

---

## References

### Official Documentation
- [Swift C++ Interoperability](https://www.swift.org/documentation/cxx-interop/)
- [Setting Up Mixed-Language Projects](https://www.swift.org/documentation/cxx-interop/project-build-setup/)
- [Swift Package Manager System Libraries](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0208-package-manager-system-library-targets.md)

### Community Resources
- [yeatse/opencv-spm](https://github.com/yeatse/opencv-spm) - Binary package reference
- [r0ml/OpenCV](https://github.com/r0ml/OpenCV) - Alternative SPM approach
- [OpenCV Installation Guide](https://docs.opencv.org/4.x/d7/d9f/tutorial_linux_install.html)

### Stack Overflow Examples
- [Using pkg-config with SPM](https://stackoverflow.com/questions/67733051/)
- [C++ Interop in SPM](https://forums.swift.org/t/c-interoperability-in-swift-package-manager/)

---

**Document Version:** 1.0
**Date:** 2024-11-16
**Phase:** 4 (OpenCV Integration)
**Status:** Research Complete ✅
**Next Phase:** Design & Implementation
