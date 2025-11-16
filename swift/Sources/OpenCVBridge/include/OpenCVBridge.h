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
// MARK: - Future Phase Functions (Phase 5+)
// ============================================================================

// Image loading and basic operations (Phase 5)
// struct ImageData {
//     int32_t width;
//     int32_t height;
//     int32_t channels;
//     std::vector<uint8_t> data;
// };
//
// Result<ImageData> loadImage(const char* path);
// bool saveImage(const char* path, const ImageData& image);

// Contour detection (Phase 5)
// struct Contour {
//     std::vector<Point> points;
//     double area;
//     Rect boundingRect;
// };
//
// std::vector<Contour> findContours(const ImageData& image);

// Morphological operations (Phase 5)
// ImageData dilate(const ImageData& image, Size kernelSize);
// ImageData erode(const ImageData& image, Size kernelSize);

} // namespace OpenCVBridge
