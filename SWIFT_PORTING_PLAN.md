# Kumiko Swift Porting Plan

## Executive Summary

This document outlines a comprehensive plan to port **Kumiko** (a Python-based comic panel detection tool) to Swift. The port will preserve all original Python code and create a parallel Swift implementation in a dedicated `swift/` directory.

---

## 1. Codebase Analysis

### Current Structure (Python)
- **Total Lines**: ~1,752 lines of Python
- **Core Modules**: 10 Python files
- **Main Components**:
  - `kumiko` - CLI entry point (157 lines)
  - `kumikolib.py` - Main Kumiko class (131 lines)
  - `lib/page.py` - Page analysis logic (405 lines)
  - `lib/panel.py` - Panel detection & operations (480 lines)
  - `lib/segment.py` - Geometric segment operations (198 lines)
  - `lib/html.py` - HTML generation (107 lines)
  - `lib/debug.py` - Debugging utilities (281 lines)

### Dependencies
| Python Library | Purpose | Lines Using It |
|---------------|---------|----------------|
| `opencv-python` (cv2) | Image processing, contour detection | ~150+ |
| `numpy` | Array operations, mathematical ops | ~80+ |
| `argparse` | CLI argument parsing | ~45 |
| `requests` | HTTP requests for URL processing | ~5 |
| Standard library | JSON, sys, os, tempfile, subprocess, etc. | Throughout |

---

## 2. Swift Equivalents & Dependencies

### 2.1 Core Dependencies

| Python | Swift Equivalent | Integration Method |
|--------|-----------------|-------------------|
| OpenCV (cv2) | OpenCV framework | Swift Package Manager or CocoaPods |
| NumPy | Native Swift arrays + OpenCV Mat | Direct implementation |
| argparse | Swift ArgumentParser | SPM package |
| requests | URLSession (Foundation) | Built-in |
| json | JSONEncoder/JSONDecoder | Built-in |
| subprocess | Process (Foundation) | Built-in |

### 2.2 OpenCV Swift Integration Options

**Option A: Swift Package Manager (Recommended)**
```swift
.package(url: "https://github.com/opencv/opencv", from: "4.8.0")
```

**Option B: Manual Integration**
- Download opencv2.xcframework
- Add to Swift package as binary target

**Option C: Create C++ Bridge**
- Use Swift-C++ interop for OpenCV functions
- Requires careful memory management

---

## 3. Architecture Design

### 3.1 Project Structure

```
swift/
├── Package.swift                    # Swift Package Manager manifest
├── README.md                        # Swift-specific documentation
├── Sources/
│   ├── Kumiko/                     # Library module (reusable)
│   │   ├── Kumiko.swift           # Main class (ports kumikolib.py)
│   │   ├── Page.swift             # Page analysis (ports lib/page.py)
│   │   ├── Panel.swift            # Panel operations (ports lib/panel.py)
│   │   ├── Segment.swift          # Geometry (ports lib/segment.py)
│   │   ├── Debug.swift            # Debugging (ports lib/debug.py)
│   │   ├── HTML.swift             # HTML generation (ports lib/html.py)
│   │   ├── Models/                # Supporting types
│   │   │   ├── PageInfo.swift     # JSON-serializable models
│   │   │   ├── PanelInfo.swift
│   │   │   └── ProcessingOptions.swift
│   │   └── Extensions/            # Swift helpers
│   │       ├── CGRect+Panel.swift
│   │       └── Mat+Extensions.swift
│   └── kumiko-cli/                # Executable module
│       └── main.swift             # CLI entry point (ports kumiko)
├── Tests/
│   ├── KumikoTests/
│   │   ├── SegmentTests.swift
│   │   ├── PanelTests.swift
│   │   ├── PageTests.swift
│   │   └── KumikoTests.swift
│   └── Resources/
│       └── test-images/           # Test comic pages
└── .github/
    └── workflows/
        └── swift.yml              # CI/CD for Swift builds
```

### 3.2 Module Breakdown

#### **Kumiko Module (Library)**
- Pure Swift library
- No executable code
- Importable by other Swift projects
- Supports macOS, Linux, iOS (potential)

#### **kumiko-cli Module (Executable)**
- Command-line tool
- Depends on Kumiko module
- Uses Swift ArgumentParser for CLI

---

## 4. Porting Strategy (Phase-by-Phase)

### Phase 1: Foundation & Setup (Week 1)
**Goal**: Establish Swift project structure and basic types

#### Tasks:
1. Create `swift/` directory structure
2. Initialize `Package.swift` with dependencies:
   - Swift ArgumentParser
   - OpenCV integration (research best method)
3. Port data models (no OpenCV yet):
   - `Models/PageInfo.swift` - JSON structures
   - `Models/PanelInfo.swift`
   - `Models/ProcessingOptions.swift`
4. Create basic protocol definitions
5. Set up unit test framework

**Deliverables**:
- ✅ Buildable Swift package
- ✅ Basic types compile
- ✅ Test harness ready

---

### Phase 2: Geometry Module (Week 2)
**Goal**: Port `Segment` class (no OpenCV dependency)

#### Tasks:
1. Port `lib/segment.py` → `Segment.swift`
   - `Segment` struct with points
   - Distance calculations
   - Angle computations
   - Segment intersection logic
   - Union operations
2. Write comprehensive unit tests
3. Validate against Python implementation

**Key Challenges**:
- NumPy operations → Swift native math
- Floating-point precision handling
- Tuple unpacking patterns

**Files**: `Segment.swift` (~250 lines estimated)

---

### Phase 3: Panel Operations (Week 3)
**Goal**: Port `Panel` class (minimal OpenCV)

#### Tasks:
1. Port `lib/panel.py` → `Panel.swift`
   - Bounding box operations
   - Overlap detection
   - Panel comparison & sorting
   - Neighbor finding logic
   - Panel merging/grouping
2. Implement `Comparable` protocol for panel sorting
3. Handle OpenCV's `boundingRect` with Swift equivalent
4. Unit tests for all panel operations

**Key Challenges**:
- Python list comprehensions → Swift `filter`, `map`
- Mutable panel arrays
- Reference vs value semantics

**Files**: `Panel.swift` (~550 lines estimated)

---

### Phase 4: OpenCV Integration (Week 4-5)
**Goal**: Integrate OpenCV for image processing

#### Tasks:
1. Research & finalize OpenCV integration approach
2. Create `Mat+Extensions.swift` for Swift-friendly OpenCV API
3. Create `CVBridge.swift` for any C++ bridging needed
4. Test basic OpenCV operations:
   - Image loading (`imread`)
   - Grayscale conversion
   - Sobel filter
   - Threshold operations
   - Contour detection
   - Line segment detection

**Key Challenges**:
- OpenCV C++ API exposure to Swift
- Memory management (Mat lifecycle)
- Pointer safety
- Platform differences (macOS vs Linux)

**Files**:
- `CVBridge.swift` (if needed, ~100 lines)
- `Mat+Extensions.swift` (~150 lines)

---

### Phase 5: Page Analysis (Week 6-7)
**Goal**: Port core page analysis algorithm

#### Tasks:
1. Port `lib/page.py` → `Page.swift`
   - Image loading & preprocessing
   - Contour detection pipeline
   - Segment extraction
   - Initial panel detection
   - Panel splitting algorithm
   - Panel merging logic
   - Deoverlapping
   - Panel expansion
   - Numbering fixes
2. Handle temporary file operations
3. Implement processing pipeline
4. Unit tests with real comic images

**Key Challenges**:
- Complex algorithm flow
- NumPy array indexing → Swift/OpenCV Mat
- Debugging image generation
- Performance optimization

**Files**: `Page.swift` (~500 lines estimated)

---

### Phase 6: Main Kumiko Class (Week 8)
**Goal**: Port orchestration logic

#### Tasks:
1. Port `kumikolib.py` → `Kumiko.swift`
   - Directory parsing
   - URL list processing
   - PDF extraction (using `pdftopm` subprocess)
   - Batch processing
   - Panel saving to files
2. Implement progress reporting
3. Error handling strategy
4. JSON output generation

**Files**: `Kumiko.swift` (~200 lines estimated)

---

### Phase 7: Debug & HTML Generation (Week 9)
**Goal**: Port debugging and visualization

#### Tasks:
1. Port `lib/debug.py` → `Debug.swift`
   - Image annotation
   - Step tracking
   - Timing information
2. Port `lib/html.py` → `HTML.swift`
   - HTML template generation
   - JSON embedding
   - Reader interface
3. Copy/adapt JavaScript assets (reader.js, jQuery, CSS)

**Files**:
- `Debug.swift` (~300 lines)
- `HTML.swift` (~150 lines)

---

### Phase 8: CLI Tool (Week 10)
**Goal**: Create command-line interface

#### Tasks:
1. Port `kumiko` → `main.swift`
2. Use Swift ArgumentParser for:
   - Input/output arguments
   - Browser options
   - HTML generation flags
   - Debug flags
   - Configuration tweaks
3. Integrate browser launching (via `Process`)
4. Error handling & help text

**Files**: `main.swift` (~200 lines estimated)

---

### Phase 9: Testing & Validation (Week 11-12)
**Goal**: Ensure parity with Python version

#### Tasks:
1. Create comprehensive test suite:
   - Unit tests for all classes
   - Integration tests with sample images
   - Regression tests against Python output
2. Test on multiple platforms:
   - macOS (arm64 & x86_64)
   - Linux (Ubuntu)
3. Performance benchmarking
4. Memory leak detection
5. Edge case handling

**Deliverables**:
- ✅ 80%+ test coverage
- ✅ Identical output to Python on test images
- ✅ Performance within 10% of Python version

---

### Phase 10: Documentation & Polish (Week 13)
**Goal**: Production-ready release

#### Tasks:
1. Write comprehensive README for Swift version
2. API documentation (DocC)
3. Usage examples
4. Migration guide (Python → Swift)
5. CI/CD setup (GitHub Actions)
6. Release checklist

**Deliverables**:
- ✅ Published documentation
- ✅ CI/CD pipeline
- ✅ v1.0 release tag

---

## 5. Technical Challenges & Solutions

### 5.1 OpenCV Integration

**Challenge**: OpenCV is primarily C++ with Python bindings. Swift integration requires care.

**Solutions**:
- **Option 1**: Use community Swift-OpenCV wrappers (if maintained)
- **Option 2**: Create minimal C++ bridge layer
- **Option 3**: Direct C++ interop (requires Swift 5.9+)
- **Recommended**: Start with Option 1, fall back to Option 2

### 5.2 NumPy Array Operations

**Challenge**: Heavy use of NumPy for array manipulation.

**Solutions**:
- Use OpenCV's `Mat` type for image data
- Use Swift native arrays for simple operations
- Port NumPy algorithms to Swift math operations
- Example: `np.dot()` → Swift vector math

### 5.3 Python Idioms → Swift

| Python Pattern | Swift Equivalent |
|---------------|-----------------|
| List comprehensions | `map`, `filter`, `compactMap` |
| `enumerate()` | `enumerated()` |
| `sorted(key=lambda)` | `sorted(by:)` |
| `min(key=lambda)` | `min(by:)` |
| `any([...])` | `.contains(where:)` |
| `all([...])` | `.allSatisfy()` |
| Duck typing | Protocols & Generics |
| `None` | Optionals (`nil`) |

### 5.4 Error Handling

**Python**: Exceptions everywhere
**Swift**: Result types, throws, optionals

**Strategy**:
- Use `throws` for recoverable errors
- Use `fatalError()` for programming errors
- Use optionals for missing data
- Create custom error enum

### 5.5 JSON Encoding

**Python**: `json.dumps()` with dicts
**Swift**: `Codable` protocol

**Strategy**:
- Define `Codable` structs for all JSON output
- Use `JSONEncoder` with custom formatting
- Match Python JSON structure exactly

---

## 6. Code Quality Standards

### 6.1 Swift Style
- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for consistency
- Document public APIs with DocC comments

### 6.2 Testing
- Minimum 70% code coverage
- Test-driven development for geometry operations
- Property-based testing for algorithms
- Regression tests against Python output

### 6.3 Performance
- Profile with Instruments
- Optimize hot paths (panel splitting)
- Consider parallelization for batch processing
- Target: within 20% of Python performance

---

## 7. Compatibility Matrix

| Feature | macOS | Linux | iOS | Windows |
|---------|-------|-------|-----|---------|
| Core Library | ✅ | ✅ | 🟡* | ❌** |
| CLI Tool | ✅ | ✅ | ❌ | ❌** |
| OpenCV | ✅ | ✅ | ✅ | 🟡*** |
| HTML Output | ✅ | ✅ | ✅ | ❌** |
| PDF Support | ✅ | ✅ | 🟡* | ❌** |

*iOS: Possible but requires adaptation (no file system access in sandbox)
**Windows: Swift on Windows requires different tooling
***OpenCV on Windows possible but not initial focus

---

## 8. Migration Path

### For Users
1. **Week 1-10**: Python version remains canonical
2. **Week 11-12**: Beta testing of Swift version
3. **Week 13+**: Swift version becomes production-ready
4. **Long-term**: Both versions maintained in parallel

### For Developers
1. All new features developed in Python first
2. Port features to Swift once stable
3. Keep JSON output formats identical
4. Share test images between implementations

---

## 9. Success Criteria

### Minimum Viable Port (MVP)
- ✅ Compiles on macOS & Linux
- ✅ CLI accepts same arguments as Python version
- ✅ Produces identical JSON output for test images
- ✅ Passes 50+ unit tests
- ✅ HTML reader works

### Full Parity
- ✅ All Python features implemented
- ✅ Performance within 20% of Python
- ✅ 80%+ test coverage
- ✅ Documentation complete
- ✅ CI/CD pipeline active

### Stretch Goals
- iOS framework for panel detection
- Swift Performance optimizations (2x Python speed)
- GPU acceleration via Metal
- SwiftUI demo app

---

## 10. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| OpenCV integration issues | Medium | High | Early prototype in Phase 4 |
| NumPy porting complexity | Medium | Medium | Start with Segment (no NumPy) |
| Performance degradation | Low | Medium | Profile early, optimize hot paths |
| Algorithm differences | Low | High | Extensive regression testing |
| Maintenance burden | High | Medium | Automated testing, CI/CD |

---

## 11. Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|------------|
| 1. Foundation | 1 week | Project structure |
| 2. Geometry | 1 week | Segment class |
| 3. Panel Ops | 1 week | Panel class |
| 4. OpenCV | 2 weeks | Image processing |
| 5. Page Analysis | 2 weeks | Core algorithm |
| 6. Kumiko Class | 1 week | Orchestration |
| 7. Debug/HTML | 1 week | Visualization |
| 8. CLI | 1 week | Command tool |
| 9. Testing | 2 weeks | Full validation |
| 10. Documentation | 1 week | Release prep |
| **Total** | **13 weeks** | **Production release** |

---

## 12. Next Steps

### Immediate Actions (Week 0)
1. ✅ Review and approve this plan
2. Create `swift/` directory structure
3. Initialize Git branch: `feature/swift-port`
4. Set up Package.swift skeleton
5. Research OpenCV integration options
6. Set up development environment

### First Milestone (Week 1)
- Buildable Swift package
- Basic types defined
- OpenCV integration method chosen
- First unit test passing

---

## 13. Resources & References

### Documentation
- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [Swift Package Manager](https://swift.org/package-manager/)
- [OpenCV Documentation](https://docs.opencv.org/)
- [Swift ArgumentParser](https://github.com/apple/swift-argument-parser)

### Similar Projects
- [SwiftCV](https://github.com/technosophos/SwiftCV) - Swift OpenCV bindings
- [swift-numerics](https://github.com/apple/swift-numerics) - Numerical computing

### Tools
- Xcode 15+ (macOS)
- Swift 5.9+ (Linux)
- SwiftLint
- DocC
- Instruments (profiling)

---

## Appendix A: File Size Estimates

| Swift File | Estimated Lines | Python Source | Python Lines |
|-----------|----------------|---------------|--------------|
| Segment.swift | 250 | segment.py | 198 |
| Panel.swift | 550 | panel.py | 480 |
| Page.swift | 500 | page.py | 405 |
| Kumiko.swift | 200 | kumikolib.py | 131 |
| Debug.swift | 300 | debug.py | 281 |
| HTML.swift | 150 | html.py | 107 |
| main.swift | 200 | kumiko | 157 |
| Models/*.swift | 150 | (embedded) | - |
| Extensions/*.swift | 200 | (N/A) | - |
| **Total** | **~2,500** | **Total** | **1,759** |

*Swift version ~42% larger due to type safety, protocols, extensions*

---

## Appendix B: Dependency Licenses

| Dependency | License | Compatible? |
|-----------|---------|------------|
| OpenCV | Apache 2.0 | ✅ Yes |
| Swift ArgumentParser | Apache 2.0 | ✅ Yes |
| Kumiko (original) | AGPL-3.0 | ✅ Yes (Swift port must also be AGPL-3.0) |

**Note**: The Swift port must maintain AGPL-3.0 license compatibility. All derivative works must also be licensed under AGPL-3.0.
