//
//  PanelTests.swift
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

/// Comprehensive tests for the Panel class
final class PanelTests: XCTestCase {

    // MARK: - Mock Page

    /// Mock page for testing panels
    class MockPage: PanelPage {
        var numbering: String = "ltr"
        var imgSize: [Int] = [800, 1200]
        var smallPanelRatio: Double = 0.1
        var panels: [Panel] = []
        var segments: [Segment] = []
    }

    var mockPage: MockPage!

    override func setUp() {
        super.setUp()
        mockPage = MockPage()
    }

    // MARK: - Initialization

    func testPanelInitWithXYWH() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
        XCTAssertTrue(panel.splittable)
    }

    func testPanelFromXYRB() {
        let panel = Panel.fromXYRB(page: mockPage, x: 10, y: 20, r: 110, b: 170)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
    }

    func testPanelFromPolygon() {
        let polygon = [[
            Point(10, 20),
            Point(110, 20),
            Point(110, 170),
            Point(10, 170)
        ]]

        let panel = Panel(page: mockPage, polygon: polygon)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
    }

    // MARK: - Geometry

    func testPanelDimensions() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.w(), 100)
        XCTAssertEqual(panel.h(), 150)
        XCTAssertEqual(panel.area(), 15000)
    }

    func testPanelDiagonal() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let diag = panel.diagonal()

        XCTAssertEqual(diag.a, Point(10, 20))
        XCTAssertEqual(diag.b, Point(110, 170))
    }

    func testPanelThresholds() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.wt(), 10.0)
        XCTAssertEqual(panel.ht(), 15.0)
    }

    func testPanelToXYWH() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let xywh = panel.toXYWH()

        XCTAssertEqual(xywh, [10, 20, 100, 150])
    }

    // MARK: - Size Checks

    func testPanelIsSmall() {
        // Panel with width = 50, height = 60
        // Page size = 800x1200, ratio = 0.1
        // Min width = 80, min height = 120
        let smallPanel = Panel(page: mockPage, xywh: [0, 0, 50, 60])
        XCTAssertTrue(smallPanel.isSmall())

        let normalPanel = Panel(page: mockPage, xywh: [0, 0, 100, 150])
        XCTAssertFalse(normalPanel.isSmall())
    }

    func testPanelIsVerySmall() {
        // Very small threshold = 0.01 (1/100)
        // Min width = 8, min height = 12
        let verySmallPanel = Panel(page: mockPage, xywh: [0, 0, 5, 5])
        XCTAssertTrue(verySmallPanel.isVerySmall())

        let smallPanel = Panel(page: mockPage, xywh: [0, 0, 50, 60])
        XCTAssertFalse(smallPanel.isVerySmall())
    }

    // MARK: - Equality

    func testPanelEquality() {
        let p1 = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let p2 = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let p3 = Panel(page: mockPage, xywh: [12, 22, 100, 150]) // Within threshold
        let p4 = Panel(page: mockPage, xywh: [30, 40, 100, 150]) // Different

        XCTAssertEqual(p1, p2)
        XCTAssertEqual(p1, p3) // Within wt/ht threshold
        XCTAssertNotEqual(p1, p4)
    }

    // MARK: - Comparison (Sorting)

    func testPanelSortingVertical() {
        let top = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let bottom = Panel(page: mockPage, xywh: [0, 200, 100, 100])

        XCTAssertTrue(top < bottom)
        XCTAssertFalse(bottom < top)
    }

    func testPanelSortingHorizontalLTR() {
        mockPage.numbering = "ltr"

        let left = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let right = Panel(page: mockPage, xywh: [200, 0, 100, 100])

        XCTAssertTrue(left < right)
        XCTAssertFalse(right < left)
    }

    func testPanelSortingHorizontalRTL() {
        mockPage.numbering = "rtl"

        let left = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let right = Panel(page: mockPage, xywh: [200, 0, 100, 100])

        // In RTL, right comes before left
        XCTAssertFalse(left < right)
        XCTAssertTrue(right < left)
    }

    func testPanelArraySorting() {
        let panels = [
            Panel(page: mockPage, xywh: [200, 0, 100, 100]),   // Right
            Panel(page: mockPage, xywh: [0, 200, 100, 100]),   // Bottom left
            Panel(page: mockPage, xywh: [0, 0, 100, 100]),     // Top left
            Panel(page: mockPage, xywh: [200, 200, 100, 100]), // Bottom right
        ]

        let sorted = panels.sorted()

        XCTAssertEqual(sorted[0].x, 0)   // Top left first
        XCTAssertEqual(sorted[0].y, 0)
        XCTAssertEqual(sorted[3].x, 200) // Bottom right last
        XCTAssertEqual(sorted[3].y, 200)
    }

    // MARK: - Overlap Detection

    func testOverlapPanelNoOverlap() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [200, 200, 100, 100])

        XCTAssertNil(p1.overlapPanel(p2))
        XCTAssertNil(p2.overlapPanel(p1))
    }

    func testOverlapPanelPartial() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [50, 50, 100, 100])

        let overlap = p1.overlapPanel(p2)
        XCTAssertNotNil(overlap)
        XCTAssertEqual(overlap?.x, 50)
        XCTAssertEqual(overlap?.y, 50)
        XCTAssertEqual(overlap?.r, 100)
        XCTAssertEqual(overlap?.b, 100)
    }

    func testOverlapPanelContained() {
        let outer = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let inner = Panel(page: mockPage, xywh: [25, 25, 50, 50])

        let overlap = outer.overlapPanel(inner)
        XCTAssertNotNil(overlap)
        XCTAssertEqual(overlap?.x, 25)
        XCTAssertEqual(overlap?.y, 25)
        XCTAssertEqual(overlap?.w(), 50)
        XCTAssertEqual(overlap?.h(), 50)
    }

    func testOverlapArea() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [50, 50, 100, 100])

        let area = p1.overlapArea(p2)
        XCTAssertEqual(area, 2500) // 50x50 overlap
    }

    func testOverlaps() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [50, 50, 100, 100])
        let p3 = Panel(page: mockPage, xywh: [200, 200, 100, 100])

        XCTAssertTrue(p1.overlaps(p2))
        XCTAssertFalse(p1.overlaps(p3))
    }

    func testContains() {
        let outer = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let inner = Panel(page: mockPage, xywh: [25, 25, 50, 50])
        let partial = Panel(page: mockPage, xywh: [50, 50, 100, 100])

        XCTAssertTrue(outer.contains(inner))
        XCTAssertFalse(outer.contains(partial))
        XCTAssertFalse(inner.contains(outer))
    }

    // MARK: - Row/Column Detection

    func testSameRowHorizontallyAligned() {
        let p1 = Panel(page: mockPage, xywh: [0, 100, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [200, 100, 100, 100])

        XCTAssertTrue(p1.sameRow(p2))
        XCTAssertTrue(p2.sameRow(p1))
    }

    func testSameRowPartialOverlap() {
        let p1 = Panel(page: mockPage, xywh: [0, 100, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [200, 150, 100, 100])

        XCTAssertTrue(p1.sameRow(p2))
    }

    func testSameRowNotInRow() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [200, 200, 100, 100])

        XCTAssertFalse(p1.sameRow(p2))
    }

    func testSameColVerticallyAligned() {
        let p1 = Panel(page: mockPage, xywh: [100, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [100, 200, 100, 100])

        XCTAssertTrue(p1.sameCol(p2))
        XCTAssertTrue(p2.sameCol(p1))
    }

    func testSameColPartialOverlap() {
        let p1 = Panel(page: mockPage, xywh: [100, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [150, 200, 100, 100])

        XCTAssertTrue(p1.sameCol(p2))
    }

    func testSameColNotInColumn() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [200, 200, 100, 100])

        XCTAssertFalse(p1.sameCol(p2))
    }

    // MARK: - Neighbor Finding

    func testFindTopPanel() {
        let top = Panel(page: mockPage, xywh: [100, 0, 100, 100])
        let middle = Panel(page: mockPage, xywh: [100, 200, 100, 100])
        let bottom = Panel(page: mockPage, xywh: [100, 400, 100, 100])

        mockPage.panels = [top, middle, bottom]

        XCTAssertNil(top.findTopPanel())
        XCTAssert(middle.findTopPanel() === top)
        XCTAssert(bottom.findTopPanel() === middle)
    }

    func testFindBottomPanel() {
        let top = Panel(page: mockPage, xywh: [100, 0, 100, 100])
        let middle = Panel(page: mockPage, xywh: [100, 200, 100, 100])
        let bottom = Panel(page: mockPage, xywh: [100, 400, 100, 100])

        mockPage.panels = [top, middle, bottom]

        XCTAssert(top.findBottomPanel() === middle)
        XCTAssert(middle.findBottomPanel() === bottom)
        XCTAssertNil(bottom.findBottomPanel())
    }

    func testFindLeftPanel() {
        let left = Panel(page: mockPage, xywh: [0, 100, 100, 100])
        let middle = Panel(page: mockPage, xywh: [200, 100, 100, 100])
        let right = Panel(page: mockPage, xywh: [400, 100, 100, 100])

        mockPage.panels = [left, middle, right]

        XCTAssertNil(left.findLeftPanel())
        XCTAssert(middle.findLeftPanel() === left)
        XCTAssert(right.findLeftPanel() === middle)
    }

    func testFindRightPanel() {
        let left = Panel(page: mockPage, xywh: [0, 100, 100, 100])
        let middle = Panel(page: mockPage, xywh: [200, 100, 100, 100])
        let right = Panel(page: mockPage, xywh: [400, 100, 100, 100])

        mockPage.panels = [left, middle, right]

        XCTAssert(left.findRightPanel() === middle)
        XCTAssert(middle.findRightPanel() === right)
        XCTAssertNil(right.findRightPanel())
    }

    func testFindNeighborPanel() {
        let center = Panel(page: mockPage, xywh: [200, 200, 100, 100])
        let top = Panel(page: mockPage, xywh: [200, 0, 100, 100])
        let bottom = Panel(page: mockPage, xywh: [200, 400, 100, 100])
        let left = Panel(page: mockPage, xywh: [0, 200, 100, 100])
        let right = Panel(page: mockPage, xywh: [400, 200, 100, 100])

        mockPage.panels = [center, top, bottom, left, right]

        XCTAssert(center.findNeighborPanel("y") === top)
        XCTAssert(center.findNeighborPanel("b") === bottom)
        XCTAssert(center.findNeighborPanel("x") === left)
        XCTAssert(center.findNeighborPanel("r") === right)
    }

    // MARK: - Panel Operations

    func testGroupWith() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [150, 150, 100, 100])

        let grouped = p1.groupWith(p2)

        XCTAssertEqual(grouped.x, 0)
        XCTAssertEqual(grouped.y, 0)
        XCTAssertEqual(grouped.r, 250)
        XCTAssertEqual(grouped.b, 250)
    }

    func testIsClose() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [120, 120, 100, 100]) // Close
        let p3 = Panel(page: mockPage, xywh: [500, 500, 100, 100]) // Far

        XCTAssertTrue(p1.isClose(p2))
        XCTAssertFalse(p1.isClose(p3))
    }

    func testBumpsInto() {
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 100])
        let p2 = Panel(page: mockPage, xywh: [50, 50, 100, 100])   // Overlaps
        let p3 = Panel(page: mockPage, xywh: [200, 200, 100, 100]) // Separate

        XCTAssertTrue(p1.bumpsInto([p2, p3]))
        XCTAssertFalse(p1.bumpsInto([p3]))
        XCTAssertFalse(p1.bumpsInto([]))
    }

    func testContainsSegment() {
        let panel = Panel(page: mockPage, xywh: [0, 0, 100, 100])

        let insideSegment = Segment((10, 10), (90, 90))
        let outsideSegment = Segment((200, 200), (300, 300))
        let crossingSegment = Segment((50, 50), (150, 150))

        XCTAssertTrue(panel.containsSegment(insideSegment))
        XCTAssertFalse(panel.containsSegment(outsideSegment))
        XCTAssertTrue(panel.containsSegment(crossingSegment))
    }

    func testGetSegments() {
        let panel = Panel(page: mockPage, xywh: [0, 0, 100, 100])

        mockPage.segments = [
            Segment((10, 10), (90, 90)),     // Inside
            Segment((200, 200), (300, 300)), // Outside
            Segment((50, 50), (150, 150)),   // Crossing
        ]

        let segments = panel.getSegments()
        XCTAssertEqual(segments.count, 2) // Inside + crossing
    }

    // MARK: - Polygon Initialization (Phase 4: OpenCV Integration)

    func testPanelFromRectangularPolygon() {
        // Test panel creation from rectangular polygon
        let polygon = [
            [Point(x: 10, y: 20), Point(x: 110, y: 20),
             Point(x: 110, y: 170), Point(x: 10, y: 170)]
        ]

        let panel = Panel(page: mockPage, polygon: polygon)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.r, 110)
        XCTAssertEqual(panel.b, 170)
        XCTAssertEqual(panel.w(), 100)
        XCTAssertEqual(panel.h(), 150)
    }

    func testPanelFromIrregularPolygon() {
        // Test with a diamond-shaped polygon
        let polygon = [
            [Point(x: 50, y: 0), Point(x: 100, y: 50),
             Point(x: 50, y: 100), Point(x: 0, y: 50)]
        ]

        let panel = Panel(page: mockPage, polygon: polygon)

        // Bounding rect should be the rectangle containing the diamond
        XCTAssertEqual(panel.x, 0)
        XCTAssertEqual(panel.y, 0)
        XCTAssertEqual(panel.r, 100)
        XCTAssertEqual(panel.b, 100)
        XCTAssertEqual(panel.w(), 100)
        XCTAssertEqual(panel.h(), 100)
    }

    func testPanelFromTrianglePolygon() {
        // Test with a triangular polygon
        let polygon = [
            [Point(x: 50, y: 0), Point(x: 0, y: 100), Point(x: 100, y: 100)]
        ]

        let panel = Panel(page: mockPage, polygon: polygon)

        XCTAssertEqual(panel.x, 0)
        XCTAssertEqual(panel.y, 0)
        XCTAssertEqual(panel.r, 100)
        XCTAssertEqual(panel.b, 100)
    }

    func testPanelFromComplexPolygon() {
        // Test with an L-shaped polygon
        let polygon = [
            [Point(x: 0, y: 0), Point(x: 50, y: 0),
             Point(x: 50, y: 50), Point(x: 100, y: 50),
             Point(x: 100, y: 100), Point(x: 0, y: 100)]
        ]

        let panel = Panel(page: mockPage, polygon: polygon)

        // Bounding rect should contain the entire L-shape
        XCTAssertEqual(panel.x, 0)
        XCTAssertEqual(panel.y, 0)
        XCTAssertEqual(panel.r, 100)
        XCTAssertEqual(panel.b, 100)
    }

    func testPanelFromPolygonWithNegativeCoords() {
        // Test with polygon containing negative coordinates
        let polygon = [
            [Point(x: -10, y: -20), Point(x: 90, y: -20),
             Point(x: 90, y: 130), Point(x: -10, y: 130)]
        ]

        let panel = Panel(page: mockPage, polygon: polygon)

        XCTAssertEqual(panel.x, -10)
        XCTAssertEqual(panel.y, -20)
        XCTAssertEqual(panel.r, 90)
        XCTAssertEqual(panel.b, 130)
    }

    // MARK: - Description

    func testPanelDescription() {
        let panel = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        XCTAssertEqual(panel.description, "10x20-110x170")
    }

    // MARK: - Hashable

    func testPanelHashable() {
        let p1 = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let p2 = Panel(page: mockPage, xywh: [10, 20, 100, 150])
        let p3 = Panel(page: mockPage, xywh: [30, 40, 100, 150])

        var set = Set<Panel>()
        set.insert(p1)
        set.insert(p2)
        set.insert(p3)

        XCTAssertEqual(set.count, 2) // p1 and p2 are equal
    }

    // MARK: - Performance

    func testPanelCreationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = Panel(page: mockPage, xywh: [i, i * 2, 100, 150])
            }
        }
    }

    func testOverlapDetectionPerformance() {
        let panels = (0..<100).map { i in
            Panel(page: mockPage, xywh: [i * 10, i * 10, 100, 100])
        }

        measure {
            for p1 in panels {
                for p2 in panels {
                    _ = p1.overlaps(p2)
                }
            }
        }
    }

    func testNeighborFindingPerformance() {
        let panels = (0..<100).map { i in
            Panel(page: mockPage, xywh: [i * 100, 0, 80, 100])
        }
        mockPage.panels = panels

        measure {
            for panel in panels {
                _ = panel.findLeftPanel()
                _ = panel.findRightPanel()
            }
        }
    }
}
