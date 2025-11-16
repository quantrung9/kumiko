//
//  OpenCVImageTests.swift
//  Kumiko Tests
//
//  Tests for OpenCV image processing functions
//  Validates Phase 5 image I/O and processing
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import XCTest
@testable import OpenCVBridge

/// Tests for OpenCV image processing functions
///
/// These tests validate the Phase 5 OpenCV bridge extensions for
/// image loading, color conversion, edge detection, and contour detection.
final class OpenCVImageTests: XCTestCase {

    // MARK: - Image Data Tests

    func testImageDataCreation() {
        let img = OpenCVBridge.ImageData(width: 100, height: 150, channels: 3)

        XCTAssertEqual(img.width, 100)
        XCTAssertEqual(img.height, 150)
        XCTAssertEqual(img.channels, 3)
        XCTAssertEqual(img.pixelCount(), 15000)
        XCTAssertEqual(img.dataSize(), 45000) // 100 * 150 * 3
    }

    func testImageDataEmpty() {
        let img1 = OpenCVBridge.ImageData()
        XCTAssertTrue(img1.empty())

        let img2 = OpenCVBridge.ImageData(width: 100, height: 150, channels: 3)
        XCTAssertFalse(img2.empty())
    }

    // MARK: - Color Conversion Tests

    func testColorConversionCodes() {
        // Test that enum values match OpenCV constants
        XCTAssertEqual(OpenCVBridge.ColorConversion.BGR2GRAY.rawValue, 6)
        XCTAssertEqual(OpenCVBridge.ColorConversion.GRAY2BGR.rawValue, 8)
        XCTAssertEqual(OpenCVBridge.ColorConversion.BGR2RGB.rawValue, 4)
    }

    // MARK: - Threshold Type Tests

    func testThresholdTypes() {
        // Test that enum values match OpenCV constants
        XCTAssertEqual(OpenCVBridge.ThresholdType.BINARY.rawValue, 0)
        XCTAssertEqual(OpenCVBridge.ThresholdType.BINARY_INV.rawValue, 1)
        XCTAssertEqual(OpenCVBridge.ThresholdType.TRUNC.rawValue, 2)
        XCTAssertEqual(OpenCVBridge.ThresholdType.TOZERO.rawValue, 3)
        XCTAssertEqual(OpenCVBridge.ThresholdType.TOZERO_INV.rawValue, 4)
    }

    // MARK: - Retrieval Mode Tests

    func testRetrievalModes() {
        // Test that enum values match OpenCV constants
        XCTAssertEqual(OpenCVBridge.RetrievalMode.EXTERNAL.rawValue, 0)
        XCTAssertEqual(OpenCVBridge.RetrievalMode.LIST.rawValue, 1)
        XCTAssertEqual(OpenCVBridge.RetrievalMode.CCOMP.rawValue, 2)
        XCTAssertEqual(OpenCVBridge.RetrievalMode.TREE.rawValue, 3)
    }

    // MARK: - Approximation Method Tests

    func testApproximationMethods() {
        // Test that enum values match OpenCV constants
        XCTAssertEqual(OpenCVBridge.ApproximationMethod.NONE.rawValue, 1)
        XCTAssertEqual(OpenCVBridge.ApproximationMethod.SIMPLE.rawValue, 2)
        XCTAssertEqual(OpenCVBridge.ApproximationMethod.TC89_L1.rawValue, 3)
        XCTAssertEqual(OpenCVBridge.ApproximationMethod.TC89_KCOS.rawValue, 4)
    }

    // MARK: - Line Segment Tests

    func testLineSegmentCreation() {
        let seg1 = OpenCVBridge.LineSegment()
        XCTAssertEqual(seg1.start.x, 0)
        XCTAssertEqual(seg1.start.y, 0)
        XCTAssertEqual(seg1.end.x, 0)
        XCTAssertEqual(seg1.end.y, 0)

        let p1 = OpenCVBridge.Point(x: 10, y: 20)
        let p2 = OpenCVBridge.Point(x: 110, y: 120)
        let seg2 = OpenCVBridge.LineSegment(s: p1, e: p2)

        XCTAssertEqual(seg2.start.x, 10)
        XCTAssertEqual(seg2.start.y, 20)
        XCTAssertEqual(seg2.end.x, 110)
        XCTAssertEqual(seg2.end.y, 120)
    }

    // MARK: - Arc Length Tests

    func testArcLengthRectangle() {
        // Create a rectangle contour: 100x150
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 0, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 150))
        contour.push_back(OpenCVBridge.Point(x: 0, y: 150))

        let length = OpenCVBridge.arcLength(contour, true)

        // Perimeter = 2 * (100 + 150) = 500
        XCTAssertEqual(length, 500.0, accuracy: 0.1)
    }

    func testArcLengthTriangle() {
        // Create a triangle contour
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 0, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 50, y: 100))

        let length = OpenCVBridge.arcLength(contour, true)

        // Side 1: 100, Side 2 and 3: sqrt(50^2 + 100^2) each ≈ 111.8
        // Total ≈ 323.6
        XCTAssertGreaterThan(length, 320.0)
        XCTAssertLessThan(length, 330.0)
    }

    func testArcLengthOpenContour() {
        // Create an open contour (line)
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 0, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 100))

        let lengthClosed = OpenCVBridge.arcLength(contour, true)
        let lengthOpen = OpenCVBridge.arcLength(contour, false)

        // Closed: 100 + 100 + 100√2 ≈ 341.4
        // Open: 100 + 100 = 200
        XCTAssertGreaterThan(lengthClosed, lengthOpen)
        XCTAssertEqual(lengthOpen, 200.0, accuracy: 0.1)
    }

    // MARK: - Approximate Polygon Tests

    func testApproxPolyDPRectangle() {
        // Create a rectangle with extra points
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 0, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 50, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 0))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 75))
        contour.push_back(OpenCVBridge.Point(x: 100, y: 150))
        contour.push_back(OpenCVBridge.Point(x: 50, y: 150))
        contour.push_back(OpenCVBridge.Point(x: 0, y: 150))
        contour.push_back(OpenCVBridge.Point(x: 0, y: 75))

        // Approximate with epsilon = 5.0
        let approx = OpenCVBridge.approxPolyDP(contour, 5.0, true)

        // Should simplify to 4 corners
        XCTAssertEqual(approx.count, 4)
    }

    func testApproxPolyDPCircle() {
        // Create a circular contour (simplified)
        var contour = std.vector<OpenCVBridge.Point>()
        let centerX: Int32 = 50
        let centerY: Int32 = 50
        let radius: Int32 = 40

        // Add 16 points around circle
        for i in 0..<16 {
            let angle = Double(i) * 2.0 * .pi / 16.0
            let x = centerX + Int32(Double(radius) * cos(angle))
            let y = centerY + Int32(Double(radius) * sin(angle))
            contour.push_back(OpenCVBridge.Point(x: x, y: y))
        }

        // With small epsilon, should keep most points
        let approxSmall = OpenCVBridge.approxPolyDP(contour, 1.0, true)
        XCTAssertGreaterThan(approxSmall.count, 8)

        // With large epsilon, should simplify more
        let approxLarge = OpenCVBridge.approxPolyDP(contour, 10.0, true)
        XCTAssertLessThan(approxLarge.count, approxSmall.count)
    }

    // MARK: - Integration Tests

    func testApproxPolyDPWithBoundingRect() {
        // Create a contour and test both operations together
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 10, y: 20))
        contour.push_back(OpenCVBridge.Point(x: 15, y: 20))
        contour.push_back(OpenCVBridge.Point(x: 110, y: 20))
        contour.push_back(OpenCVBridge.Point(x: 110, y: 170))
        contour.push_back(OpenCVBridge.Point(x: 10, y: 170))

        // Approximate
        let approx = OpenCVBridge.approxPolyDP(contour, 2.0, true)

        // Should simplify to 4 corners
        XCTAssertEqual(approx.count, 4)

        // Get bounding rect of approximated contour
        let result = OpenCVBridge.boundingRectFromPoints(approx)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 10)
        XCTAssertEqual(result.value.y, 20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 150)
    }

    // MARK: - Edge Cases

    func testArcLengthEmptyContour() {
        let contour = std.vector<OpenCVBridge.Point>()
        let length = OpenCVBridge.arcLength(contour, true)

        XCTAssertEqual(length, 0.0)
    }

    func testApproxPolyDPEmptyContour() {
        let contour = std.vector<OpenCVBridge.Point>()
        let approx = OpenCVBridge.approxPolyDP(contour, 1.0, true)

        XCTAssertTrue(approx.isEmpty)
    }

    func testArcLengthSinglePoint() {
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 50, y: 50))

        let length = OpenCVBridge.arcLength(contour, true)

        XCTAssertEqual(length, 0.0, accuracy: 0.1)
    }

    func testApproxPolyDPSinglePoint() {
        var contour = std.vector<OpenCVBridge.Point>()
        contour.push_back(OpenCVBridge.Point(x: 50, y: 50))

        let approx = OpenCVBridge.approxPolyDP(contour, 1.0, true)

        XCTAssertEqual(approx.count, 1)
        XCTAssertEqual(approx[0].x, 50)
        XCTAssertEqual(approx[0].y, 50)
    }

    // MARK: - Performance Tests

    func testArcLengthPerformance() {
        // Create a large contour
        var contour = std.vector<OpenCVBridge.Point>()
        for i in 0..<1000 {
            contour.push_back(OpenCVBridge.Point(
                x: Int32(i % 100),
                y: Int32(i / 100)
            ))
        }

        measure {
            for _ in 0..<100 {
                let _ = OpenCVBridge.arcLength(contour, true)
            }
        }
    }

    func testApproxPolyDPPerformance() {
        // Create a large contour
        var contour = std.vector<OpenCVBridge.Point>()
        for i in 0..<1000 {
            contour.push_back(OpenCVBridge.Point(
                x: Int32(i % 100),
                y: Int32(i / 100)
            ))
        }

        measure {
            for _ in 0..<100 {
                let _ = OpenCVBridge.approxPolyDP(contour, 1.0, true)
            }
        }
    }
}
