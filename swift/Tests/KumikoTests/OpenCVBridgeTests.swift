//
//  OpenCVBridgeTests.swift
//  Kumiko Tests
//
//  Tests for OpenCV C++ bridge layer
//  Validates OpenCV integration via Swift 5.9+ C++ interop
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import XCTest
@testable import OpenCVBridge

/// Tests for the OpenCV C++ bridge
///
/// These tests validate that the C++ interop layer correctly wraps
/// OpenCV functions and provides a Swift-friendly API.
final class OpenCVBridgeTests: XCTestCase {

    // MARK: - Basic Type Tests

    func testPointCreation() {
        let point = OpenCVBridge.Point(x: 10, y: 20)

        XCTAssertEqual(point.x, 10)
        XCTAssertEqual(point.y, 20)
    }

    func testSizeCreation() {
        let size = OpenCVBridge.Size(width: 100, height: 150)

        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 150)
    }

    func testRectCreation() {
        let rect = OpenCVBridge.Rect(x: 10, y: 20, width: 100, height: 150)

        XCTAssertEqual(rect.x, 10)
        XCTAssertEqual(rect.y, 20)
        XCTAssertEqual(rect.width, 100)
        XCTAssertEqual(rect.height, 150)
    }

    func testRectConvenienceMethods() {
        let rect = OpenCVBridge.Rect(x: 10, y: 20, width: 100, height: 150)

        XCTAssertEqual(rect.right(), 110)
        XCTAssertEqual(rect.bottom(), 170)
        XCTAssertEqual(rect.area(), 15000)
    }

    // MARK: - boundingRectFromPoints Tests

    func testBoundingRectFromRectangularPoints() {
        // Create points forming a perfect rectangle
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 10, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 170))
        points.push_back(OpenCVBridge.Point(x: 10, y: 170))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success, "boundingRectFromPoints should succeed with valid points")
        XCTAssertEqual(result.value.x, 10)
        XCTAssertEqual(result.value.y, 20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 150)
    }

    func testBoundingRectFromIrregularPolygon() {
        // Create points forming a diamond shape
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 50, y: 0))   // Top
        points.push_back(OpenCVBridge.Point(x: 100, y: 50)) // Right
        points.push_back(OpenCVBridge.Point(x: 50, y: 100)) // Bottom
        points.push_back(OpenCVBridge.Point(x: 0, y: 50))   // Left

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 0)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 100)
    }

    func testBoundingRectFromTriangle() {
        // Create triangle points
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 50, y: 0))   // Top
        points.push_back(OpenCVBridge.Point(x: 0, y: 100))  // Bottom-left
        points.push_back(OpenCVBridge.Point(x: 100, y: 100)) // Bottom-right

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 0)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 100)
    }

    func testBoundingRectFromSinglePoint() {
        // Single point should create a zero-size bounding box at that point
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 42, y: 73))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 42)
        XCTAssertEqual(result.value.y, 73)
        // Width and height might be 0 or 1 depending on OpenCV implementation
        XCTAssertLessThanOrEqual(result.value.width, 1)
        XCTAssertLessThanOrEqual(result.value.height, 1)
    }

    func testBoundingRectFromTwoPoints() {
        // Two points forming a line
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 10, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 120))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 10)
        XCTAssertEqual(result.value.y, 20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 100)
    }

    func testBoundingRectFromEmptyPoints() {
        // Empty vector should fail
        let points = std.vector<OpenCVBridge.Point>()
        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertFalse(result.success, "boundingRectFromPoints should fail with empty points")
    }

    func testBoundingRectWithNegativeCoordinates() {
        // Test with negative coordinates
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: -10, y: -20))
        points.push_back(OpenCVBridge.Point(x: 90, y: 130))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, -10)
        XCTAssertEqual(result.value.y, -20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 150)
    }

    func testBoundingRectWithDuplicatePoints() {
        // Test with duplicate points (should still work)
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 10, y: 20))
        points.push_back(OpenCVBridge.Point(x: 10, y: 20))
        points.push_back(OpenCVBridge.Point(x: 110, y: 170))
        points.push_back(OpenCVBridge.Point(x: 110, y: 170))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 10)
        XCTAssertEqual(result.value.y, 20)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 150)
    }

    // MARK: - Complex Polygon Tests

    func testBoundingRectFromComplexPolygon() {
        // Test with a more complex polygon (L-shape approximation)
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 0, y: 0))
        points.push_back(OpenCVBridge.Point(x: 50, y: 0))
        points.push_back(OpenCVBridge.Point(x: 50, y: 50))
        points.push_back(OpenCVBridge.Point(x: 100, y: 50))
        points.push_back(OpenCVBridge.Point(x: 100, y: 100))
        points.push_back(OpenCVBridge.Point(x: 0, y: 100))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 0)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 100)
        XCTAssertEqual(result.value.height, 100)
    }

    func testBoundingRectFromPentagon() {
        // Test with a regular pentagon approximation
        var points = std.vector<OpenCVBridge.Point>()
        points.push_back(OpenCVBridge.Point(x: 50, y: 0))
        points.push_back(OpenCVBridge.Point(x: 98, y: 35))
        points.push_back(OpenCVBridge.Point(x: 79, y: 90))
        points.push_back(OpenCVBridge.Point(x: 21, y: 90))
        points.push_back(OpenCVBridge.Point(x: 2, y: 35))

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 2)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 96)
        XCTAssertEqual(result.value.height, 90)
    }

    // MARK: - Large Data Tests

    func testBoundingRectFromManyPoints() {
        // Test with many points to verify performance
        var points = std.vector<OpenCVBridge.Point>()

        // Create 1000 random points within bounds
        for i in 0..<1000 {
            let x = Int32(i % 100)
            let y = Int32(i / 100)
            points.push_back(OpenCVBridge.Point(x: x, y: y))
        }

        let result = OpenCVBridge.boundingRectFromPoints(points)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.value.x, 0)
        XCTAssertEqual(result.value.y, 0)
        XCTAssertEqual(result.value.width, 99)
        XCTAssertEqual(result.value.height, 9)
    }

    // MARK: - Performance Tests

    func testBoundingRectPerformance() {
        // Measure performance of bounding rect calculation
        var points = std.vector<OpenCVBridge.Point>()

        // Create 100 points
        for i in 0..<100 {
            points.push_back(OpenCVBridge.Point(
                x: Int32((i * 7) % 100),
                y: Int32((i * 13) % 100)
            ))
        }

        measure {
            for _ in 0..<100 {
                let _ = OpenCVBridge.boundingRectFromPoints(points)
            }
        }
    }
}
