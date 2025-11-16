//
//  OpenCVBridge.h
//  Kumiko OpenCV Bridge
//
//  Swift-friendly C++ wrapper for OpenCV functions
//  Enables Swift 5.9+ C++ interoperability with OpenCV
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

#pragma once

#include <vector>
#include <cstdint>

namespace OpenCVBridge {

// ============================================================================
// MARK: - Basic Geometric Types
// ============================================================================

/// 2D Point with integer coordinates
///
/// Compatible with Swift via C++ interop.
/// Swift usage: `OpenCVBridge.Point(x: 10, y: 20)`
struct Point {
    int32_t x;
    int32_t y;

    Point() : x(0), y(0) {}
    Point(int32_t x_, int32_t y_) : x(x_), y(y_) {}
};

/// 2D Size with integer dimensions
///
/// Compatible with Swift via C++ interop.
/// Swift usage: `OpenCVBridge.Size(width: 100, height: 150)`
struct Size {
    int32_t width;
    int32_t height;

    Size() : width(0), height(0) {}
    Size(int32_t w, int32_t h) : width(w), height(h) {}
};

/// Rectangle defined by top-left corner and size
///
/// Compatible with Swift via C++ interop.
/// Swift usage: `OpenCVBridge.Rect(x: 10, y: 20, width: 100, height: 150)`
struct Rect {
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;

    Rect() : x(0), y(0), width(0), height(0) {}
    Rect(int32_t x_, int32_t y_, int32_t w, int32_t h)
        : x(x_), y(y_), width(w), height(h) {}

    /// Get right edge (x + width)
    int32_t right() const { return x + width; }

    /// Get bottom edge (y + height)
    int32_t bottom() const { return y + height; }

    /// Calculate area (width * height)
    int32_t area() const { return width * height; }
};

// ============================================================================
// MARK: - Result Type for Failable Operations
// ============================================================================

/// Result type for operations that can fail
///
/// Provides a type-safe way to return success/failure without exceptions.
/// Swift usage:
///   let result = OpenCVBridge.boundingRectFromPoints(points)
///   guard result.success else { return nil }
///   let rect = result.value
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
/// Phase 4 requirement: Replace Panel polygon stub with OpenCV implementation
/// Python equivalent: cv2.boundingRect(contour)
///
/// This function takes a vector of 2D points forming a polygon and returns
/// the axis-aligned bounding rectangle that contains all points.
///
/// @param points Vector of 2D points forming the polygon
/// @return Result<Rect> containing the bounding rectangle, or failure if points is empty
///
/// Swift usage:
/// ```swift
/// var points = std.vector<OpenCVBridge.Point>()
/// points.push_back(OpenCVBridge.Point(x: 10, y: 20))
/// points.push_back(OpenCVBridge.Point(x: 110, y: 170))
///
/// let result = OpenCVBridge.boundingRectFromPoints(points)
/// if result.success {
///     let rect = result.value
///     print("Bounding rect: \(rect.x), \(rect.y), \(rect.width), \(rect.height)")
/// }
/// ```
Result<Rect> boundingRectFromPoints(const std::vector<Point>& points);

// ============================================================================
// MARK: - Phase 5: Image Data Structure
// ============================================================================

/// Image data container compatible with Swift
///
/// Stores raw pixel data in row-major order.
/// Compatible with cv::Mat via helper functions in the implementation.
struct ImageData {
    int32_t width;
    int32_t height;
    int32_t channels;  // 1 = grayscale, 3 = BGR color
    std::vector<uint8_t> data;  // Row-major pixel data

    ImageData() : width(0), height(0), channels(0) {}

    ImageData(int32_t w, int32_t h, int32_t c)
        : width(w), height(h), channels(c) {
        data.resize(static_cast<size_t>(w) * h * c);
    }

    /// Get total number of pixels
    int32_t pixelCount() const { return width * height; }

    /// Get total data size in bytes
    size_t dataSize() const { return data.size(); }

    /// Check if image is empty
    bool empty() const { return width == 0 || height == 0 || data.empty(); }
};

// ============================================================================
// MARK: - Phase 5: Image I/O
// ============================================================================

/// Load an image from file
///
/// Python equivalent: cv2.imread(filename)
///
/// @param path File path to load
/// @return Result<ImageData> containing the loaded image, or failure if load fails
///
/// Swift usage:
/// ```swift
/// let result = OpenCVBridge.loadImage("/path/to/image.jpg")
/// guard result.success else { throw PageError.imageLoadFailed }
/// let img = result.value
/// ```
Result<ImageData> loadImage(const char* path);

/// Save an image to file
///
/// Python equivalent: cv2.imwrite(filename, img)
///
/// @param path File path to save
/// @param image Image data to save
/// @return true if save succeeded, false otherwise
bool saveImage(const char* path, const ImageData& image);

// ============================================================================
// MARK: - Phase 5: Color Conversion
// ============================================================================

/// Color conversion codes (matching OpenCV constants)
enum ColorConversion {
    BGR2GRAY = 6,   // cv::COLOR_BGR2GRAY
    GRAY2BGR = 8,   // cv::COLOR_GRAY2BGR
    BGR2RGB = 4     // cv::COLOR_BGR2RGB
};

/// Convert image color space
///
/// Python equivalent: cv2.cvtColor(img, code)
///
/// @param src Source image
/// @param code Color conversion code
/// @return Converted image
///
/// Swift usage:
/// ```swift
/// let gray = OpenCVBridge.cvtColor(img, Int32(OpenCVBridge.ColorConversion.BGR2GRAY.rawValue))
/// ```
ImageData cvtColor(const ImageData& src, int32_t code);

// ============================================================================
// MARK: - Phase 5: Image Processing
// ============================================================================

/// Apply Sobel edge detection
///
/// Python equivalent: cv2.Sobel(src, cv2.CV_16S, dx, dy, ksize=3)
///
/// @param src Source grayscale image
/// @param dx Order of the derivative x (0 or 1)
/// @param dy Order of the derivative y (0 or 1)
/// @return Sobel-filtered image (CV_16S depth)
ImageData sobel(const ImageData& src, int32_t dx, int32_t dy);

/// Convert image to absolute values and scale to 8-bit
///
/// Python equivalent: cv2.convertScaleAbs(src)
///
/// @param src Source image (any depth)
/// @return 8-bit absolute value image
ImageData convertScaleAbs(const ImageData& src);

/// Weighted sum of two images
///
/// Python equivalent: cv2.addWeighted(src1, alpha, src2, beta, gamma)
/// Result = src1 * alpha + src2 * beta + gamma
///
/// @param src1 First source image
/// @param alpha Weight for first image
/// @param src2 Second source image
/// @param beta Weight for second image
/// @param gamma Scalar added to weighted sum
/// @return Weighted sum image
ImageData addWeighted(
    const ImageData& src1, double alpha,
    const ImageData& src2, double beta,
    double gamma
);

// ============================================================================
// MARK: - Phase 5: Thresholding
// ============================================================================

/// Threshold type constants (matching OpenCV)
enum ThresholdType {
    BINARY = 0,      // cv::THRESH_BINARY
    BINARY_INV = 1,  // cv::THRESH_BINARY_INV
    TRUNC = 2,       // cv::THRESH_TRUNC
    TOZERO = 3,      // cv::THRESH_TOZERO
    TOZERO_INV = 4   // cv::THRESH_TOZERO_INV
};

/// Apply fixed-level threshold to image
///
/// Python equivalent: cv2.threshold(src, thresh, maxval, type)
///
/// @param src Source image
/// @param thresh Threshold value
/// @param maxval Maximum value for THRESH_BINARY
/// @param type Threshold type
/// @return Result<ImageData> containing thresholded image
///
/// Swift usage:
/// ```swift
/// let result = OpenCVBridge.threshold(sobel, 100.0, 255.0,
///                                     Int32(OpenCVBridge.ThresholdType.BINARY.rawValue))
/// ```
Result<ImageData> threshold(
    const ImageData& src,
    double thresh,
    double maxval,
    int32_t type
);

// ============================================================================
// MARK: - Phase 5: Contour Detection
// ============================================================================

/// Contour retrieval modes (matching OpenCV)
enum RetrievalMode {
    EXTERNAL = 0,     // cv::RETR_EXTERNAL - retrieve only extreme outer contours
    LIST = 1,         // cv::RETR_LIST - retrieve all contours without hierarchy
    CCOMP = 2,        // cv::RETR_CCOMP - retrieve all contours organized in 2-level hierarchy
    TREE = 3          // cv::RETR_TREE - retrieve all contours with full hierarchy
};

/// Contour approximation methods (matching OpenCV)
enum ApproximationMethod {
    NONE = 1,         // cv::CHAIN_APPROX_NONE - store all points
    SIMPLE = 2,       // cv::CHAIN_APPROX_SIMPLE - compress horizontal/vertical/diagonal segments
    TC89_L1 = 3,      // cv::CHAIN_APPROX_TC89_L1
    TC89_KCOS = 4     // cv::CHAIN_APPROX_TC89_KCOS
};

/// Find contours in a binary image
///
/// Python equivalent: cv2.findContours(image, mode, method)
///
/// @param image Binary source image (8-bit single-channel)
/// @param mode Contour retrieval mode
/// @param method Contour approximation method
/// @return Vector of contours, each contour is a vector of points
///
/// Swift usage:
/// ```swift
/// let contours = OpenCVBridge.findContours(
///     thresh,
///     Int32(OpenCVBridge.RetrievalMode.EXTERNAL.rawValue),
///     Int32(OpenCVBridge.ApproximationMethod.SIMPLE.rawValue)
/// )
/// ```
std::vector<std::vector<Point>> findContours(
    const ImageData& image,
    int32_t mode,
    int32_t method
);

/// Calculate contour perimeter
///
/// Python equivalent: cv2.arcLength(contour, closed)
///
/// @param contour Input contour
/// @param closed Whether contour is closed
/// @return Perimeter length
double arcLength(const std::vector<Point>& contour, bool closed);

/// Approximate polygon from contour
///
/// Python equivalent: cv2.approxPolyDP(contour, epsilon, closed)
///
/// @param contour Input contour
/// @param epsilon Approximation accuracy (max distance between original and approximated contour)
/// @param closed Whether contour is closed
/// @return Approximated polygon as vector of points
std::vector<Point> approxPolyDP(
    const std::vector<Point>& contour,
    double epsilon,
    bool closed
);

// ============================================================================
// MARK: - Phase 5: Line Segment Detection
// ============================================================================

/// Line segment (start and end points)
struct LineSegment {
    Point start;
    Point end;

    LineSegment() : start(), end() {}
    LineSegment(const Point& s, const Point& e) : start(s), end(e) {}
};

/// Detect line segments using Line Segment Detector (LSD)
///
/// Python equivalent:
/// ```python
/// lsd = cv2.createLineSegmentDetector(0)
/// lines = lsd.detect(gray)[0]
/// ```
///
/// @param image Grayscale source image
/// @return Vector of detected line segments
///
/// Swift usage:
/// ```swift
/// let lines = OpenCVBridge.detectLineSegments(gray)
/// for line in lines {
///     let segment = Segment((Int(line.start.x), Int(line.start.y)),
///                          (Int(line.end.x), Int(line.end.y)))
/// }
/// ```
std::vector<LineSegment> detectLineSegments(const ImageData& image);

} // namespace OpenCVBridge
