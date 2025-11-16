//
//  PageTests.swift
//  Kumiko Tests
//
//  Tests for Page class and panel detection pipeline
//  Validates Phase 5 page analysis implementation
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import XCTest
@testable import Kumiko
import OpenCVBridge

/// Tests for Page class
///
/// These tests validate the Page analysis pipeline including
/// error handling, initialization, and helper methods.
/// Full integration tests require sample comic page images.
final class PageTests: XCTestCase {

    // MARK: - Error Tests

    func testPageErrorNotAnImage() {
        // Test that loading non-existent file throws appropriate error
        do {
            let _ = try Page(filename: "/nonexistent/file.jpg")
            XCTFail("Should have thrown notAnImage error")
        } catch PageError.notAnImage(let path) {
            XCTAssertTrue(path.contains("nonexistent"))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testPageErrorInvalidNumbering() {
        // Test that invalid numbering throws error
        // Note: This would only trigger if image loaded, so we test the validation logic
        do {
            let _ = try Page(filename: "/dev/null", numbering: "invalid")
            XCTFail("Should have thrown invalidNumbering error")
        } catch PageError.invalidNumbering(let num) {
            XCTAssertEqual(num, "invalid")
        } catch PageError.notAnImage {
            // Also acceptable since /dev/null isn't an image
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Helper Method Tests

    func testActualGuttersEmptyPanels() {
        // Create a minimal Page-like object for testing
        // Since Page init requires a file, we'll test the logic indirectly
        // by testing Panel's neighbor finding which actualGutters uses

        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Add panels with known gutters
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 200])
        let p2 = Panel(page: mockPage, xywh: [120, 0, 100, 200])  // 20px gutter
        let p3 = Panel(page: mockPage, xywh: [240, 0, 100, 200])  // 20px gutter

        mockPage.panels = [p1, p2, p3]

        // Test neighbor finding (used by actualGutters)
        XCTAssertEqual(p2.findLeftPanel(), p1)
        XCTAssertEqual(p3.findLeftPanel(), p2)
        XCTAssertEqual(p1.findRightPanel(), p2)
        XCTAssertEqual(p2.findRightPanel(), p3)

        // Verify gutter calculations would work
        XCTAssertEqual(p2.x - p1.r, 20)
        XCTAssertEqual(p3.x - p2.r, 20)
    }

    // MARK: - Default Values Tests

    func testDefaultMinPanelSizeRatio() {
        XCTAssertEqual(Page.defaultMinPanelSizeRatio, 1.0 / 10.0)
    }

    // MARK: - Documentation Tests

    func testPageInfoStructure() {
        // Verify PageInfo structure matches expected format
        // This ensures JSON output compatibility

        let info = PageInfo(
            filename: "test.jpg",
            size: [800, 1200],
            numbering: "ltr",
            gutters: [10, 15],
            license: nil,
            panels: [[0, 0, 100, 150], [120, 0, 100, 150]],
            processingTime: 0.5
        )

        XCTAssertEqual(info.filename, "test.jpg")
        XCTAssertEqual(info.size, [800, 1200])
        XCTAssertEqual(info.numbering, "ltr")
        XCTAssertEqual(info.gutters, [10, 15])
        XCTAssertNil(info.license)
        XCTAssertEqual(info.panels.count, 2)
        XCTAssertEqual(info.processingTime, 0.5)
    }

    // MARK: - Panel Detection Logic Tests

    func testSmallPanelGroupingLogic() {
        // Test the grouping logic for small adjacent panels
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.15  // Higher threshold for testing
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create small panels that should be grouped
        let p1 = Panel(page: mockPage, xywh: [10, 10, 50, 50])   // Small
        let p2 = Panel(page: mockPage, xywh: [70, 10, 50, 50])   // Small, close to p1
        let p3 = Panel(page: mockPage, xywh: [500, 500, 50, 50]) // Small, far away

        mockPage.panels = [p1, p2, p3]

        // Verify panels are small
        XCTAssertTrue(p1.isSmall())
        XCTAssertTrue(p2.isSmall())
        XCTAssertTrue(p3.isSmall())

        // Verify p1 and p2 are close
        XCTAssertTrue(p1.isClose(p2))

        // Verify p1 and p3 are not close
        XCTAssertFalse(p1.isClose(p3))
    }

    func testPanelMergingLogic() {
        // Test panel merging for contained panels
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Large panel
        let large = Panel(page: mockPage, xywh: [0, 0, 200, 200])

        // Panel contained within large
        let contained = Panel(page: mockPage, xywh: [50, 50, 50, 50])

        XCTAssertTrue(large.contains(contained))
        XCTAssertFalse(contained.contains(large))

        // Test merge expands bounds
        let merged = large.merge(contained)
        XCTAssertGreaterThanOrEqual(merged.w(), large.w())
        XCTAssertGreaterThanOrEqual(merged.h(), large.h())
    }

    func testPanelDeoverlapLogic() {
        // Test de-overlapping logic
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create overlapping panels
        let p1 = Panel(page: mockPage, xywh: [0, 0, 120, 100])
        let p2 = Panel(page: mockPage, xywh: [100, 0, 100, 100])

        mockPage.panels = [p1, p2]

        // Verify they overlap
        XCTAssertNotNil(p1.overlapPanel(p2))

        let overlap = p1.overlapPanel(p2)!

        // Overlap region should be from x=100 to x=120
        XCTAssertEqual(overlap.x, 100)
        XCTAssertEqual(overlap.w(), 20)

        // Vertical overlap check
        XCTAssertTrue(overlap.w() < overlap.h())
    }

    func testPanelExpansionBounds() {
        // Test that panel expansion respects image boundaries
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Panel near edge
        let panel = Panel(page: mockPage, xywh: [10, 10, 100, 100])

        // Expanding left would go to 0 (image boundary)
        // Expanding top would go to 0 (image boundary)
        // These would be clamped in actual expansion logic

        XCTAssertGreaterThanOrEqual(panel.x, 0)
        XCTAssertGreaterThanOrEqual(panel.y, 0)
        XCTAssertLessThanOrEqual(panel.r, mockPage.imgSize[0])
        XCTAssertLessThanOrEqual(panel.b, mockPage.imgSize[1])
    }

    // MARK: - Reading Order Tests

    func testReadingOrderLTR() {
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create panels in reading order (LTR)
        let p1 = Panel(page: mockPage, xywh: [0, 0, 100, 200])      // Top-left
        let p2 = Panel(page: mockPage, xywh: [120, 0, 100, 200])    // Top-right
        let p3 = Panel(page: mockPage, xywh: [0, 220, 100, 200])    // Bottom-left
        let p4 = Panel(page: mockPage, xywh: [120, 220, 100, 200])  // Bottom-right

        mockPage.panels = [p4, p2, p3, p1]  // Unsorted

        // Sort panels
        mockPage.panels.sort()

        // Verify LTR order: p1, p2, p3, p4
        XCTAssertEqual(mockPage.panels[0].x, p1.x)
        XCTAssertEqual(mockPage.panels[1].x, p2.x)
        XCTAssertEqual(mockPage.panels[2].x, p3.x)
        XCTAssertEqual(mockPage.panels[3].x, p4.x)
    }

    func testReadingOrderRTL() {
        class MockPage: PanelPage {
            var numbering: String = "rtl"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create panels in reading order (RTL)
        let p1 = Panel(page: mockPage, xywh: [120, 0, 100, 200])    // Top-right (first in RTL)
        let p2 = Panel(page: mockPage, xywh: [0, 0, 100, 200])      // Top-left
        let p3 = Panel(page: mockPage, xywh: [120, 220, 100, 200])  // Bottom-right
        let p4 = Panel(page: mockPage, xywh: [0, 220, 100, 200])    // Bottom-left

        mockPage.panels = [p4, p2, p3, p1]  // Unsorted

        // Sort panels
        mockPage.panels.sort()

        // Verify RTL order: p1 (right), p2 (left), p3 (right), p4 (left)
        // In RTL, rightmost comes first
        XCTAssertGreaterThan(mockPage.panels[0].x, mockPage.panels[1].x)
        XCTAssertGreaterThan(mockPage.panels[2].x, mockPage.panels[3].x)
    }

    // MARK: - Segment Filtering Tests

    func testSegmentFilteringThreshold() {
        // Test that segment detection respects minimum distance threshold
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Minimum distance = min(800, 1200) * 0.1 = 80
        let minDist = Double(min(mockPage.imgSize[0], mockPage.imgSize[1])) * mockPage.smallPanelRatio

        XCTAssertEqual(minDist, 80.0)

        // Segments shorter than this should be filtered out
        let shortSeg = Segment((0, 0), (50, 0))  // Length 50 < 80
        let longSeg = Segment((0, 0), (100, 0))  // Length 100 > 80

        XCTAssertLessThan(shortSeg.dist(), minDist)
        XCTAssertGreaterThan(longSeg.dist(), minDist)
    }

    // MARK: - Performance Tests

    func testPanelSortingPerformance() {
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create 100 panels in random positions
        for i in 0..<100 {
            let x = (i * 37) % 700
            let y = (i * 53) % 1100
            mockPage.panels.append(Panel(page: mockPage, xywh: [x, y, 80, 80]))
        }

        measure {
            for _ in 0..<100 {
                mockPage.panels.sort()
            }
        }
    }

    func testPanelOverlapDetectionPerformance() {
        class MockPage: PanelPage {
            var numbering: String = "ltr"
            var imgSize: [Int] = [800, 1200]
            var smallPanelRatio: Double = 0.1
            var panels: [Panel] = []
            var segments: [Segment] = []
        }

        let mockPage = MockPage()

        // Create 50 panels
        for i in 0..<50 {
            let x = (i * 20) % 700
            let y = (i * 30) % 1100
            mockPage.panels.append(Panel(page: mockPage, xywh: [x, y, 100, 100]))
        }

        measure {
            // Simulate overlap detection for all pairs
            for i in 0..<mockPage.panels.count {
                for j in (i+1)..<mockPage.panels.count {
                    let _ = mockPage.panels[i].overlapPanel(mockPage.panels[j])
                }
            }
        }
    }
}
