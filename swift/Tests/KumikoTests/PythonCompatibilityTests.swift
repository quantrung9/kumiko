//
//  PythonCompatibilityTests.swift
//  Kumiko Tests
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import XCTest
@testable import Kumiko

/// Tests to validate Swift implementation against Python behavior
///
/// These tests use known outputs from the Python implementation to ensure
/// the Swift port produces identical results.
final class PythonCompatibilityTests: XCTestCase {

    // MARK: - Segment Python Compatibility

    func testSegmentDistancePythonCompat() {
        // Test cases validated against Python lib/segment.py

        // Case 1: Horizontal segment
        let s1 = Segment((0, 0), (100, 0))
        XCTAssertEqual(s1.dist(), 100.0, accuracy: 0.001)
        XCTAssertEqual(s1.distX(), 100)
        XCTAssertEqual(s1.distY(), 0)

        // Case 2: Vertical segment
        let s2 = Segment((50, 0), (50, 75))
        XCTAssertEqual(s2.dist(), 75.0, accuracy: 0.001)
        XCTAssertEqual(s2.distX(), 0)
        XCTAssertEqual(s2.distY(), 75)

        // Case 3: Diagonal (3-4-5 triangle scaled by 10)
        let s3 = Segment((0, 0), (30, 40))
        XCTAssertEqual(s3.dist(), 50.0, accuracy: 0.001)
        XCTAssertEqual(s3.distX(), 30)
        XCTAssertEqual(s3.distY(), 40)
    }

    func testSegmentBoundingBoxPythonCompat() {
        // Python: Segment((30, 40), (10, 20)).to_xyrb()
        // Expected: [10, 20, 30, 40]
        let s = Segment((30, 40), (10, 20))

        XCTAssertEqual(s.toXYRB(), [10, 20, 30, 40])
        XCTAssertEqual(s.left(), 10)
        XCTAssertEqual(s.top(), 20)
        XCTAssertEqual(s.right(), 30)
        XCTAssertEqual(s.bottom(), 40)
    }

    func testSegmentCenterPythonCompat() {
        // Python: Segment((10, 20), (30, 60)).center()
        // Expected: (20, 40)
        let s = Segment((10, 20), (30, 60))
        let center = s.center()

        XCTAssertEqual(center.x, 20)
        XCTAssertEqual(center.y, 40)
    }

    func testSegmentAnglePythonCompat() {
        // Horizontal segment - angle should be 0
        let horizontal = Segment((0, 0), (10, 0))
        XCTAssertEqual(horizontal.angle(), 0.0, accuracy: 0.001)

        // Vertical segment - angle should be π/2
        let vertical = Segment((0, 0), (0, 10))
        XCTAssertEqual(vertical.angle(), .pi / 2, accuracy: 0.001)

        // 45° diagonal
        let diagonal = Segment((0, 0), (10, 10))
        XCTAssertEqual(diagonal.angle(), .pi / 4, accuracy: 0.001)
    }

    func testSegmentProjectionPythonCompat() {
        // Test cases matching Python's projected_point using NumPy

        // Case 1: Point above horizontal segment
        // Python: Segment((0, 0), (10, 0)).projected_point((5, 5))
        // Expected: (5, 0)
        let s1 = Segment((0, 0), (10, 0))
        XCTAssertEqual(s1.projectedPoint(Point(5, 5)), Point(5, 0))

        // Case 2: Point to the side of vertical segment
        // Python: Segment((0, 0), (0, 10)).projected_point((5, 5))
        // Expected: (0, 5)
        let s2 = Segment((0, 0), (0, 10))
        XCTAssertEqual(s2.projectedPoint(Point(5, 5)), Point(0, 5))

        // Case 3: Point near diagonal segment
        // Python: Segment((0, 0), (10, 10)).projected_point((10, 0))
        // Expected: (5, 5) - midpoint of diagonal
        let s3 = Segment((0, 0), (10, 10))
        XCTAssertEqual(s3.projectedPoint(Point(10, 0)), Point(5, 5))
    }

    func testSegmentIntersectionPythonCompat() {
        // Test cases validated against Python's intersect method

        // Case 1: Overlapping horizontal segments
        // Python: Segment((0, 0), (10, 0)).intersect(Segment((5, 0), (15, 0)))
        // Expected: Segment((5, 0), (10, 0))
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, 0), (15, 0))
        let intersection = s1.intersect(s2)

        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection?.a, Point(5, 0))
        XCTAssertEqual(intersection?.b, Point(10, 0))

        // Case 2: Perpendicular segments (should not intersect due to angle check)
        let s3 = Segment((0, 0), (10, 0))
        let s4 = Segment((5, -5), (5, 5))
        XCTAssertNil(s3.intersect(s4))

        // Case 3: Parallel but separated segments
        let s5 = Segment((0, 0), (10, 0))
        let s6 = Segment((20, 0), (30, 0))
        XCTAssertNil(s5.intersect(s6))
    }

    func testSegmentUnionPythonCompat() {
        // Test cases validated against Python's union method

        // Case 1: Overlapping segments
        // Python: Segment((0, 0), (10, 0)).union(Segment((5, 0), (15, 0)))
        // Expected: Segment((0, 0), (15, 0))
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, 0), (15, 0))
        let union = s1.union(s2)

        XCTAssertNotNil(union)
        // Union can have endpoints in either order
        XCTAssertTrue(
            (union?.a == Point(0, 0) && union?.b == Point(15, 0)) ||
            (union?.a == Point(15, 0) && union?.b == Point(0, 0))
        )

        // Case 2: Non-intersecting segments
        let s3 = Segment((0, 0), (10, 0))
        let s4 = Segment((20, 0), (30, 0))
        XCTAssertNil(s3.union(s4))
    }

    func testSegmentUnionAllPythonCompat() {
        // Test union_all static method matching Python behavior

        // Multiple overlapping segments should be unioned
        let segments = [
            Segment((0, 0), (5, 0)),
            Segment((4, 0), (10, 0)),
            Segment((9, 0), (15, 0)),
        ]

        let unioned = Segment.unionAll(segments)

        // Should result in one segment from 0 to 15
        XCTAssertEqual(unioned.count, 1)
        XCTAssertTrue(
            (unioned[0].a == Point(0, 0) && unioned[0].b == Point(15, 0)) ||
            (unioned[0].a == Point(15, 0) && unioned[0].b == Point(0, 0))
        )
    }

    func testSegmentEqualityPythonCompat() {
        // Python Segment equality is bidirectional
        // Segment(a, b) == Segment(b, a) should be true

        let s1 = Segment((10, 20), (30, 40))
        let s2 = Segment((30, 40), (10, 20))

        XCTAssertEqual(s1, s2)

        // Different segments should not be equal
        let s3 = Segment((10, 20), (30, 41))
        XCTAssertNotEqual(s1, s3)
    }

    // MARK: - PanelInfo Python Compatibility

    func testPanelInfoXYWHPythonCompat() {
        // Test XYWH conversion matching Python's panel.to_xywh()
        let panel = PanelInfo(x: 10, y: 20, width: 100, height: 150)

        XCTAssertEqual(panel.toXYWH(), [10, 20, 100, 150])
        XCTAssertEqual(panel.right, 110)
        XCTAssertEqual(panel.bottom, 170)
    }

    func testPanelInfoFromXYRBPythonCompat() {
        // Test fromXYRB matching Python's Panel.from_xyrb()
        let panel = PanelInfo.fromXYRB(x: 10, y: 20, right: 110, bottom: 170)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.width, 100)
        XCTAssertEqual(panel.height, 150)
    }

    // MARK: - ProcessingOptions Python Compatibility

    func testProcessingOptionsNumberingPythonCompat() {
        // Test numbering matches Python's numbering logic

        let ltrOptions = ProcessingOptions(rtl: false)
        XCTAssertEqual(ltrOptions.numbering, "ltr")

        let rtlOptions = ProcessingOptions(rtl: true)
        XCTAssertEqual(rtlOptions.numbering, "rtl")
    }

    func testProcessingOptionsDefaultsPythonCompat() {
        // Match Python's default options
        let options = ProcessingOptions.default

        XCTAssertFalse(options.debug)
        XCTAssertFalse(options.progress)
        XCTAssertFalse(options.rtl)
        XCTAssertTrue(options.panelExpansion)
        XCTAssertNil(options.minPanelSizeRatio)
    }

    // MARK: - Panel Python Compatibility

    func testPanelGeometryPythonCompat() {
        // Mock page for testing
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()

        // Test panel dimensions matching Python's Panel class
        let panel = Panel(page: page, xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
        XCTAssertEqual(panel.w(), 100)
        XCTAssertEqual(panel.h(), 150)
        XCTAssertEqual(panel.area(), 15000)
    }

    func testPanelFromXYRBPythonCompat() {
        // Match Python's Panel.from_xyrb() static method
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()
        let panel = Panel.fromXYRB(page: page, x: 10, y: 20, r: 110, b: 170)

        XCTAssertEqual(panel.toXYWH(), [10, 20, 100, 150])
    }

    func testPanelOverlapPythonCompat() {
        // Test overlap detection matching Python behavior
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()

        let p1 = Panel(page: page, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: page, xywh: [50, 50, 100, 100])

        let overlap = p1.overlapPanel(p2)
        XCTAssertNotNil(overlap)
        XCTAssertEqual(overlap?.toXYWH(), [50, 50, 50, 50])
        XCTAssertEqual(overlap?.area(), 2500)
    }

    func testPanelSortingPythonCompat() {
        // Test panel sorting matching Python's __lt__ implementation
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()

        let topLeft = Panel(page: page, xywh: [0, 0, 100, 100])
        let topRight = Panel(page: page, xywh: [200, 0, 100, 100])
        let bottomLeft = Panel(page: page, xywh: [0, 200, 100, 100])

        // Vertical ordering takes precedence
        XCTAssertTrue(topLeft < bottomLeft)
        XCTAssertTrue(topRight < bottomLeft)

        // Horizontal ordering within same row
        XCTAssertTrue(topLeft < topRight)
    }

    func testPanelDescriptionPythonCompat() {
        // Match Python's __str__ method
        class TestPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let page = TestPage()
        let panel = Panel(page: page, xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.description, "10x20-110x170")
    }
}
