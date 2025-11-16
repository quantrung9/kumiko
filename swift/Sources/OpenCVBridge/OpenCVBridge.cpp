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
#include <opencv2/imgcodecs.hpp>  // For imread/imwrite

// For Line Segment Detector
#ifdef HAVE_OPENCV_LSD
#include <opencv2/line_descriptor.hpp>
#endif

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
// MARK: - Phase 5: Image Data Conversion Helpers
// ============================================================================

/// Convert cv::Mat to ImageData
///
/// Copies pixel data from OpenCV Mat to our ImageData structure.
/// Handles multi-channel images and various data types.
static ImageData matToImageData(const cv::Mat& mat) {
    ImageData img(
        static_cast<int32_t>(mat.cols),
        static_cast<int32_t>(mat.rows),
        static_cast<int32_t>(mat.channels())
    );

    // Ensure Mat is continuous in memory for efficient copy
    if (mat.isContinuous()) {
        size_t dataSize = mat.total() * mat.elemSize();
        img.data.assign(mat.data, mat.data + dataSize);
    } else {
        // Copy row by row if not continuous
        size_t rowSize = mat.cols * mat.elemSize();
        img.data.reserve(mat.total() * mat.elemSize());
        for (int i = 0; i < mat.rows; ++i) {
            const uint8_t* rowPtr = mat.ptr<uint8_t>(i);
            img.data.insert(img.data.end(), rowPtr, rowPtr + rowSize);
        }
    }

    return img;
}

/// Convert ImageData to cv::Mat
///
/// Creates an OpenCV Mat from our ImageData structure.
/// The Mat shares memory with ImageData, so ImageData must remain valid.
static cv::Mat imageDataToMat(const ImageData& img) {
    int type = CV_8UC1;  // Default to grayscale

    if (img.channels == 3) {
        type = CV_8UC3;  // BGR color
    } else if (img.channels == 4) {
        type = CV_8UC4;  // BGRA color
    }

    // Create Mat without copying data (shares memory)
    // Note: ImageData must remain valid while Mat is in use
    return cv::Mat(
        img.height,
        img.width,
        type,
        const_cast<uint8_t*>(img.data.data())
    );
}

/// Convert ImageData to cv::Mat with deep copy
///
/// Creates an OpenCV Mat from ImageData with a full copy of the pixel data.
/// The returned Mat owns its own memory.
static cv::Mat imageDataToMatCopy(const ImageData& img) {
    int type = CV_8UC1;

    if (img.channels == 3) {
        type = CV_8UC3;
    } else if (img.channels == 4) {
        type = CV_8UC4;
    }

    cv::Mat mat(img.height, img.width, type);
    std::memcpy(mat.data, img.data.data(), img.data.size());

    return mat;
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

// ============================================================================
// MARK: - Phase 5: Image I/O Implementation
// ============================================================================

Result<ImageData> loadImage(const char* path) {
    try {
        cv::Mat img = cv::imread(path, cv::IMREAD_COLOR);

        if (img.empty()) {
            return Result<ImageData>::failure();
        }

        return Result<ImageData>(matToImageData(img));

    } catch (const cv::Exception& e) {
        return Result<ImageData>::failure();
    } catch (...) {
        return Result<ImageData>::failure();
    }
}

bool saveImage(const char* path, const ImageData& image) {
    try {
        cv::Mat mat = imageDataToMat(image);
        return cv::imwrite(path, mat);

    } catch (const cv::Exception& e) {
        return false;
    } catch (...) {
        return false;
    }
}

// ============================================================================
// MARK: - Phase 5: Color Conversion Implementation
// ============================================================================

ImageData cvtColor(const ImageData& src, int32_t code) {
    try {
        cv::Mat srcMat = imageDataToMat(src);
        cv::Mat dstMat;

        cv::cvtColor(srcMat, dstMat, code);

        return matToImageData(dstMat);

    } catch (...) {
        // Return empty image on error
        return ImageData();
    }
}

// ============================================================================
// MARK: - Phase 5: Image Processing Implementation
// ============================================================================

ImageData sobel(const ImageData& src, int32_t dx, int32_t dy) {
    try {
        cv::Mat srcMat = imageDataToMat(src);
        cv::Mat dstMat;

        // Use CV_16S depth for Sobel to handle negative gradients
        cv::Sobel(srcMat, dstMat, CV_16S, dx, dy, 3, 1, 0, cv::BORDER_DEFAULT);

        return matToImageData(dstMat);

    } catch (...) {
        return ImageData();
    }
}

ImageData convertScaleAbs(const ImageData& src) {
    try {
        cv::Mat srcMat = imageDataToMat(src);
        cv::Mat dstMat;

        cv::convertScaleAbs(srcMat, dstMat);

        return matToImageData(dstMat);

    } catch (...) {
        return ImageData();
    }
}

ImageData addWeighted(
    const ImageData& src1, double alpha,
    const ImageData& src2, double beta,
    double gamma
) {
    try {
        cv::Mat src1Mat = imageDataToMat(src1);
        cv::Mat src2Mat = imageDataToMat(src2);
        cv::Mat dstMat;

        cv::addWeighted(src1Mat, alpha, src2Mat, beta, gamma, dstMat);

        return matToImageData(dstMat);

    } catch (...) {
        return ImageData();
    }
}

// ============================================================================
// MARK: - Phase 5: Thresholding Implementation
// ============================================================================

Result<ImageData> threshold(
    const ImageData& src,
    double thresh,
    double maxval,
    int32_t type
) {
    try {
        cv::Mat srcMat = imageDataToMat(src);
        cv::Mat dstMat;

        cv::threshold(srcMat, dstMat, thresh, maxval, type);

        return Result<ImageData>(matToImageData(dstMat));

    } catch (const cv::Exception& e) {
        return Result<ImageData>::failure();
    } catch (...) {
        return Result<ImageData>::failure();
    }
}

// ============================================================================
// MARK: - Phase 5: Contour Detection Implementation
// ============================================================================

std::vector<std::vector<Point>> findContours(
    const ImageData& image,
    int32_t mode,
    int32_t method
) {
    std::vector<std::vector<Point>> result;

    try {
        cv::Mat img = imageDataToMatCopy(image);  // Deep copy for findContours
        std::vector<std::vector<cv::Point>> cvContours;

        cv::findContours(img, cvContours, mode, method);

        // Convert cv::Point to our Point type
        result.reserve(cvContours.size());
        for (const auto& cvContour : cvContours) {
            std::vector<Point> contour;
            contour.reserve(cvContour.size());

            for (const auto& cvPt : cvContour) {
                contour.push_back(fromCvPoint(cvPt));
            }

            result.push_back(std::move(contour));
        }

    } catch (...) {
        // Return empty vector on error
    }

    return result;
}

double arcLength(const std::vector<Point>& contour, bool closed) {
    try {
        // Convert to cv::Point
        std::vector<cv::Point> cvContour;
        cvContour.reserve(contour.size());

        for (const auto& pt : contour) {
            cvContour.push_back(toCvPoint(pt));
        }

        return cv::arcLength(cvContour, closed);

    } catch (...) {
        return 0.0;
    }
}

std::vector<Point> approxPolyDP(
    const std::vector<Point>& contour,
    double epsilon,
    bool closed
) {
    std::vector<Point> result;

    try {
        // Convert to cv::Point
        std::vector<cv::Point> cvContour;
        cvContour.reserve(contour.size());

        for (const auto& pt : contour) {
            cvContour.push_back(toCvPoint(pt));
        }

        std::vector<cv::Point> cvApprox;
        cv::approxPolyDP(cvContour, cvApprox, epsilon, closed);

        // Convert back to our Point type
        result.reserve(cvApprox.size());
        for (const auto& cvPt : cvApprox) {
            result.push_back(fromCvPoint(cvPt));
        }

    } catch (...) {
        // Return empty vector on error
    }

    return result;
}

// ============================================================================
// MARK: - Phase 5: Line Segment Detection Implementation
// ============================================================================

std::vector<LineSegment> detectLineSegments(const ImageData& image) {
    std::vector<LineSegment> result;

    try {
        cv::Mat img = imageDataToMat(image);

        // Create Line Segment Detector
        cv::Ptr<cv::LineSegmentDetector> lsd = cv::createLineSegmentDetector(cv::LSD_REFINE_STD);

        // Detect lines
        std::vector<cv::Vec4f> lines;
        lsd->detect(img, lines);

        // Convert to our LineSegment type
        result.reserve(lines.size());
        for (const auto& line : lines) {
            LineSegment seg;
            seg.start.x = static_cast<int32_t>(std::round(line[0]));
            seg.start.y = static_cast<int32_t>(std::round(line[1]));
            seg.end.x = static_cast<int32_t>(std::round(line[2]));
            seg.end.y = static_cast<int32_t>(std::round(line[3]));

            result.push_back(seg);
        }

    } catch (...) {
        // Return empty vector on error
    }

    return result;
}

} // namespace OpenCVBridge
