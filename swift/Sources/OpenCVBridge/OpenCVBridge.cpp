//
//  OpenCVBridge.cpp
//  Kumiko OpenCV Bridge
//
//  Swift-friendly C++ wrapper for OpenCV functions
//  Enables Swift 5.9+ C++ interoperability with OpenCV
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

#include "OpenCVBridge.h"

// Include OpenCV headers
#include <opencv2/core.hpp>
#include <opencv2/imgproc.hpp>

namespace OpenCVBridge {

// ============================================================================
// MARK: - Helper Functions (Internal)
// ============================================================================

/// Convert OpenCVBridge::Point to cv::Point
///
/// Internal helper for type conversion between our Swift-friendly types
/// and OpenCV's native types.
static cv::Point toCvPoint(const Point& p) {
    return cv::Point(p.x, p.y);
}

/// Convert cv::Point to OpenCVBridge::Point
///
/// Internal helper for type conversion from OpenCV's native types
/// to our Swift-friendly types.
static Point fromCvPoint(const cv::Point& p) {
    return Point(static_cast<int32_t>(p.x), static_cast<int32_t>(p.y));
}

/// Convert cv::Rect to OpenCVBridge::Rect
///
/// Internal helper for type conversion from OpenCV's native types
/// to our Swift-friendly types.
static Rect fromCvRect(const cv::Rect& r) {
    return Rect(
        static_cast<int32_t>(r.x),
        static_cast<int32_t>(r.y),
        static_cast<int32_t>(r.width),
        static_cast<int32_t>(r.height)
    );
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
        // cv::boundingRect calculates the minimal up-right bounding rectangle
        // for the specified point set
        cv::Rect cvRect = cv::boundingRect(cvPoints);

        // Convert back to our type
        Rect result = fromCvRect(cvRect);

        return Result<Rect>(result);

    } catch (const cv::Exception& e) {
        // OpenCV-specific error occurred
        // In Phase 7 (debug mode), we could log the error:
        // std::cerr << "OpenCV error in boundingRectFromPoints: " << e.what() << std::endl;
        return Result<Rect>::failure();

    } catch (const std::exception& e) {
        // Standard C++ exception
        // std::cerr << "Standard exception in boundingRectFromPoints: " << e.what() << std::endl;
        return Result<Rect>::failure();

    } catch (...) {
        // Unknown error
        // std::cerr << "Unknown error in boundingRectFromPoints" << std::endl;
        return Result<Rect>::failure();
    }
}

} // namespace OpenCVBridge
