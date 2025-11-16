# Phase 5: Page Analysis Algorithm - Design Document

## Executive Summary

Phase 5 implements the core panel detection algorithm in the Page class. This is the most complex phase, integrating OpenCV image processing, contour detection, and panel manipulation algorithms to automatically detect comic panels from images.

**Estimated Time**: 2 weeks
**Complexity**: Very High
**Dependencies**: Phase 4 (OpenCV Integration) ✅

---

## Python Implementation Analysis

### File: `lib/page.py` (404 lines)

The Python Page class implements a sophisticated pipeline:

```python
def __init__(self):
    # 1. Load image with cv.imread()
    # 2. Convert to grayscale
    # 3. Apply Sobel edge detection
    # 4. Get contours from thresholded image
    # 5. Get line segments using LSD (Line Segment Detector)
    # 6. Get initial panels from contours
    # 7. Group small panels
    # 8. Split panels using segments
    # 9. Exclude small panels
    # 10. Merge overlapping panels
    # 11. De-overlap panels
    # 12. Expand panels (optional)
    # 13. Group big panels
    # 14. Fix panel numbering (reading order)
```

### Key Methods

| Method | Purpose | Complexity |
|--------|---------|-----------|
| `__init__` | Main processing pipeline | High |
| `get_contours()` | Sobel + threshold + findContours | Medium |
| `get_segments()` | Line Segment Detector (LSD) | Medium |
| `get_initial_panels()` | Contours → Panels | Medium |
| `group_small_panels()` | Merge small adjacent panels | High |
| `split_panels()` | Split panels using segments | Very High |
| `exclude_small_panels()` | Filter by size | Low |
| `deoverlap_panels()` | Remove overlaps | Medium |
| `merge_panels()` | Merge contained panels | Medium |
| `expand_panels()` | Expand into gutters | Medium |
| `fix_panels_numbering()` | Reading order sort | Low |
| `group_big_panels()` | Group large panels | Medium |
| `actual_gutters()` | Calculate gutter sizes | Low |

---

## Swift Architecture Design

### Module Structure

```
Phase 5 Components
├── OpenCV Bridge Extensions (C++)
│   ├── Image I/O (imread, imwrite)
│   ├── Image Processing (cvtColor, Sobel, threshold)
│   ├── Contour Detection (findContours, approxPolyDP, arcLength)
│   └── Line Segment Detector (createLineSegmentDetector)
│
└── Kumiko Library (Swift)
    ├── Page.swift (main class, ~600-800 lines)
    ├── PageInfo.swift (already exists, minor updates)
    └── ProcessingOptions.swift (already exists, updates)
```

---

## Implementation Plan

### Phase 5A: OpenCV Bridge Extensions (Days 1-3)

#### Required OpenCV Functions

**Image I/O:**
```cpp
Result<ImageData> loadImage(const char* path);
bool saveImage(const char* path, const ImageData& image);
```

**Image Processing:**
```cpp
ImageData cvtColor(const ImageData& src, int code); // BGR2GRAY
ImageData sobel(const ImageData& src, int dx, int dy);
ImageData convertScaleAbs(const ImageData& src);
ImageData addWeighted(const ImageData& src1, double alpha,
                      const ImageData& src2, double beta, double gamma);
Result<ImageData> threshold(const ImageData& src, double thresh,
                            double maxval, int type);
```

**Contour Detection:**
```cpp
struct Contour {
    std::vector<Point> points;
};

std::vector<Contour> findContours(const ImageData& image, int mode, int method);
double arcLength(const Contour& contour, bool closed);
std::vector<Point> approxPolyDP(const Contour& contour, double epsilon, bool closed);
```

**Line Segment Detector:**
```cpp
struct LineSegment {
    Point start;
    Point end;
};

std::vector<LineSegment> detectLineSegments(const ImageData& image);
```

#### ImageData Structure

```cpp
struct ImageData {
    int32_t width;
    int32_t height;
    int32_t channels;  // 1 for grayscale, 3 for BGR
    std::vector<uint8_t> data;  // Row-major pixel data

    ImageData() : width(0), height(0), channels(0) {}
    ImageData(int32_t w, int32_t h, int32_t c)
        : width(w), height(h), channels(c) {
        data.resize(w * h * c);
    }
};
```

### Phase 5B: Page Class Foundation (Days 4-6)

#### Page Class Structure

```swift
public class Page: PanelPage {
    // MARK: - Properties

    /// Image file path
    public let filename: String

    /// Original color image
    private var img: OpenCVBridge.ImageData?

    /// Grayscale image
    private var gray: OpenCVBridge.ImageData?

    /// Sobel-filtered image
    private var sobel: OpenCVBridge.ImageData?

    /// Detected contours
    private var contours: [[OpenCVBridge.Point]] = []

    /// Image size [width, height]
    public var imgSize: [Int]

    /// Reading direction ("ltr" or "rtl")
    public var numbering: String

    /// Detected panels
    public var panels: [Panel] = []

    /// Detected segments
    public var segments: [Segment] = []

    /// Minimum panel size ratio (default 1/10)
    public var smallPanelRatio: Double

    /// Whether to expand panels into gutters
    public let panelExpansion: Bool

    /// Processing time in seconds
    public var processingTime: Double?

    /// Optional URL for web sources
    public let url: String?

    /// Optional license information
    public var license: LicenseInfo?

    // MARK: - Initialization

    public init(
        filename: String,
        numbering: String? = nil,
        debug: Bool = false,
        url: String? = nil,
        minPanelSizeRatio: Double? = nil,
        panelExpansion: Bool = true
    ) throws {
        self.filename = filename
        self.numbering = numbering ?? "ltr"
        self.url = url
        self.smallPanelRatio = minPanelSizeRatio ?? Page.defaultMinPanelSizeRatio
        self.panelExpansion = panelExpansion

        let startTime = Date()

        // Load image
        let imgResult = OpenCVBridge.loadImage(filename)
        guard imgResult.success else {
            throw PageError.notAnImage(filename)
        }
        self.img = imgResult.value
        self.imgSize = [Int(img!.width), Int(img!.height)]

        // Load license if exists
        self.license = try? self.loadLicense()

        // Run processing pipeline
        try self.processImage()

        self.processingTime = Date().timeIntervalSince(startTime)
    }

    // MARK: - Processing Pipeline

    private func processImage() throws {
        // 1. Convert to grayscale
        guard let img = self.img else { return }
        self.gray = OpenCVBridge.cvtColor(img, ColorConversion.bgr2gray)

        // 2. Apply Sobel edge detection
        try self.applySobel()

        // 3. Get contours
        try self.getContours()

        // 4. Get line segments
        try self.getSegments()

        // 5. Get initial panels from contours
        self.getInitialPanels()

        // 6. Group small panels
        self.groupSmallPanels()

        // 7. Split panels using segments
        self.splitPanels()

        // 8. Exclude small panels
        self.excludeSmallPanels()

        // 9. Merge panels
        self.mergePanels()

        // 10. De-overlap panels
        self.deoverlapPanels()

        // 11. Exclude small panels again
        self.excludeSmallPanels()

        // 12. Expand panels (optional)
        if self.panelExpansion {
            self.panels.sort()
            self.expandPanels()
        }

        // 13. Add default panel if none detected
        if self.panels.isEmpty {
            self.panels.append(Panel(
                page: self,
                xywh: [0, 0, self.imgSize[0], self.imgSize[1]]
            ))
        }

        // 14. Group big panels
        self.groupBigPanels()

        // 15. Fix panel numbering
        self.fixPanelsNumbering()
    }
}
```

### Phase 5C: Core Processing Methods (Days 7-10)

#### 1. Sobel Edge Detection

```swift
private func applySobel() throws {
    guard let gray = self.gray else { return }

    // Gradient X
    let gradX = OpenCVBridge.sobel(gray, dx: 1, dy: 0)
    let absGradX = OpenCVBridge.convertScaleAbs(gradX)

    // Gradient Y
    let gradY = OpenCVBridge.sobel(gray, dx: 0, dy: 1)
    let absGradY = OpenCVBridge.convertScaleAbs(gradY)

    // Combine gradients
    self.sobel = OpenCVBridge.addWeighted(
        absGradX, 0.5,
        absGradY, 0.5,
        0.0
    )
}
```

#### 2. Contour Detection

```swift
private func getContours() throws {
    guard let sobel = self.sobel else { return }

    // Threshold: values above 100 become white, rest black
    let threshResult = OpenCVBridge.threshold(
        sobel,
        thresh: 100.0,
        maxval: 255.0,
        type: ThresholdType.binary
    )

    guard threshResult.success else {
        throw PageError.contourDetectionFailed
    }

    // Find contours
    self.contours = OpenCVBridge.findContours(
        threshResult.value,
        mode: RetrievalMode.external,
        method: ApproximationMethod.simple
    )
}
```

#### 3. Line Segment Detection

```swift
private func getSegments() throws {
    guard let gray = self.gray else { return }

    var segments: [Segment]? = nil
    var minDist = Double(min(imgSize[0], imgSize[1])) * smallPanelRatio

    let lines = OpenCVBridge.detectLineSegments(gray)

    while segments == nil || segments!.count > 500 {
        segments = []

        for line in lines {
            let dx = line.start.x - line.end.x
            let dy = line.start.y - line.end.y
            let dist = sqrt(Double(dx * dx + dy * dy))

            if dist >= minDist {
                segments!.append(Segment(
                    (Int(line.start.x), Int(line.start.y)),
                    (Int(line.end.x), Int(line.end.y))
                ))
            }
        }

        minDist *= 1.1
    }

    self.segments = Segment.unionAll(segments!)
}
```

#### 4. Initial Panel Detection

```swift
private func getInitialPanels() {
    self.panels = []

    for contour in contours {
        let arcLength = OpenCVBridge.arcLength(contour, closed: true)
        let epsilon = 0.001 * arcLength
        let approx = OpenCVBridge.approxPolyDP(contour, epsilon, closed: true)

        // Convert to Point array for Panel
        let polygon = [approx.map { Point(x: Int($0.x), y: Int($0.y)) }]

        let panel = Panel(page: self, polygon: polygon)

        if panel.isVerySmall() {
            continue
        }

        self.panels.append(panel)
    }
}
```

#### 5. Panel Grouping & Splitting

```swift
private func groupSmallPanels() {
    let smallPanels = panels.filter { $0.isSmall() }
    var groups: [Int: [Panel]] = [:]
    var groupId = 0

    // Group adjacent small panels
    for (i, p1) in smallPanels.enumerated() {
        for p2 in smallPanels[(i+1)...] {
            if p1.isClose(p2) {
                // Merge groups or create new group
                // (Complex grouping logic from Python)
            }
        }
    }

    // Replace grouped panels with merged panels
    // (Implementation details...)
}

private func splitPanels() {
    var didSplit = true

    while didSplit {
        didSplit = false

        for panel in panels.sorted(by: { $0.area() > $1.area() }) {
            if let split = panel.split() {
                didSplit = true
                panels.removeAll { $0 === panel }
                panels.append(contentsOf: split.subpanels)
                break
            }
        }
    }
}
```

### Phase 5D: Testing (Days 11-12)

#### Test Strategy

1. **Unit Tests**:
   - OpenCV bridge functions (each function tested)
   - Page initialization
   - Individual processing methods
   - Edge cases (empty images, single panel, complex layouts)

2. **Integration Tests**:
   - Full pipeline with sample images
   - Python compatibility tests
   - Performance benchmarks

3. **Test Fixtures**:
   - Sample comic page images
   - Expected panel coordinates
   - Regression test suite

#### Test Files

```swift
// OpenCVImageTests.swift (~200 lines)
- testLoadImage()
- testSaveImage()
- testCvtColor()
- testSobel()
- testThreshold()
- testFindContours()
- testLineSegmentDetector()

// PageTests.swift (~300 lines)
- testPageInitialization()
- testContourDetection()
- testSegmentDetection()
- testInitialPanelDetection()
- testPanelGrouping()
- testPanelSplitting()
- testPanelMerging()
- testFullPipeline()

// PageIntegrationTests.swift (~200 lines)
- testSimplePage()
- testComplexPage()
- testMangaPage()
- testPerformance()
```

### Phase 5E: Documentation (Days 13-14)

- Update README.md
- Create PHASE5_CHECKLIST.md
- Document OpenCV bridge extensions
- Create usage examples
- Performance analysis

---

## OpenCV Functions Reference

### Image I/O
- `cv::imread()` - Load image from file
- `cv::imwrite()` - Save image to file

### Color Conversion
- `cv::cvtColor()` - Convert BGR to grayscale (CV_BGR2GRAY)

### Edge Detection
- `cv::Sobel()` - Compute image gradients
- `cv::convertScaleAbs()` - Convert to absolute values
- `cv::addWeighted()` - Weighted sum of images

### Thresholding
- `cv::threshold()` - Binary threshold (THRESH_BINARY)

### Contour Detection
- `cv::findContours()` - Find contours (RETR_EXTERNAL, CHAIN_APPROX_SIMPLE)
- `cv::arcLength()` - Calculate contour perimeter
- `cv::approxPolyDP()` - Approximate polygon

### Line Detection
- `cv::createLineSegmentDetector()` - Create LSD instance
- `lsd->detect()` - Detect line segments

---

## Error Handling

### Swift Errors

```swift
enum PageError: Error {
    case notAnImage(String)
    case imageLoadFailed(String)
    case contourDetectionFailed
    case invalidNumbering(String)
    case processingFailed(String)
}
```

### C++ Error Handling

All OpenCV operations wrapped in try-catch:

```cpp
Result<ImageData> loadImage(const char* path) {
    try {
        cv::Mat img = cv::imread(path);
        if (img.empty()) {
            return Result<ImageData>::failure();
        }
        return Result<ImageData>(convertMatToImageData(img));
    } catch (...) {
        return Result<ImageData>::failure();
    }
}
```

---

## Performance Considerations

### Optimization Strategies

1. **Image Memory Management**:
   - Use `cv::Mat` efficiently
   - Minimize copies between Swift and C++
   - Release large images when no longer needed

2. **Algorithm Optimizations**:
   - Cache contour calculations
   - Limit LSD segments to 500 (adaptive threshold)
   - Early exit for simple layouts

3. **Parallel Processing**:
   - OpenCV uses multi-threading internally
   - Consider parallel panel processing for large images

### Expected Performance

| Image Size | Processing Time | Panel Count |
|-----------|----------------|-------------|
| 800x1200 | 0.5-1.0s | 1-6 panels |
| 1600x2400 | 1.0-2.0s | 4-12 panels |
| 3200x4800 | 2.0-4.0s | 6-20 panels |

---

## Risks & Mitigation

### High Risk

1. **Complex Panel Splitting Algorithm**
   - Risk: Most complex part, hard to debug
   - Mitigation: Incremental testing, debug visualizations

2. **OpenCV Memory Management**
   - Risk: Memory leaks at Swift-C++ boundary
   - Mitigation: Careful Result<T> usage, proper destructors

### Medium Risk

3. **Contour Detection Sensitivity**
   - Risk: Different results than Python
   - Mitigation: Threshold tuning, comparison tests

4. **Performance**
   - Risk: Slower than Python version
   - Mitigation: Profiling, optimization passes

---

## Success Criteria

✅ Page class loads images and detects panels
✅ Contour detection matches Python results (±5%)
✅ Line segment detection functional
✅ Panel splitting algorithm working
✅ Full pipeline completes without errors
✅ Comprehensive test coverage (50+ tests)
✅ Processing time < 2x Python version
✅ Documentation complete

---

## File Deliverables

### New Files

```
swift/Sources/OpenCVBridge/
├── include/OpenCVBridge.h (extended, +300 lines)
└── OpenCVBridge.cpp (extended, +500 lines)

swift/Sources/Kumiko/
└── Page.swift (new, ~700 lines)

swift/Tests/KumikoTests/
├── OpenCVImageTests.swift (new, ~200 lines)
├── PageTests.swift (new, ~300 lines)
└── PageIntegrationTests.swift (new, ~200 lines)

swift/
├── PHASE5_CHECKLIST.md (new)
└── README.md (updated)
```

### Modified Files

- Package.swift (minor updates if needed)
- Panel.swift (minor additions for split support)
- ProcessingOptions.swift (minor updates)

### Total Additions

- ~800 lines C++
- ~700 lines Swift (Page class)
- ~700 lines Swift (tests)
- ~200 lines documentation
- **Total: ~2400 lines**

---

## Timeline

| Days | Tasks | Deliverables |
|------|-------|-------------|
| 1-3 | OpenCV bridge extensions | Image I/O, processing, contours, LSD |
| 4-6 | Page class foundation | Page.swift with initialization |
| 7-10 | Core processing methods | All pipeline methods implemented |
| 11-12 | Testing | 50+ tests, integration tests |
| 13-14 | Documentation & polish | README, checklist, examples |

**Total: 14 days (2 weeks)**

---

## Next Steps After Phase 5

**Phase 6: Main Kumiko Class**
- Integrate Page processing
- Batch processing support
- JSON output generation
- Error handling & reporting

---

**Document Version:** 1.0
**Date:** 2024-11-16
**Phase:** 5 (Page Analysis Algorithm)
**Status:** Design Complete ✅
**Next:** Implementation
