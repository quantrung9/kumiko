//
//  SegmentTests.swift
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

/// Comprehensive tests for the Segment class
///
/// These tests validate the Swift implementation against the Python version's behavior
final class SegmentTests: XCTestCase {

    // MARK: - Point Tests

    func testPointCreation() {
        let p1 = Point(10, 20)
        XCTAssertEqual(p1.x, 10)
        XCTAssertEqual(p1.y, 20)

        let p2 = Point((30, 40))
        XCTAssertEqual(p2.x, 30)
        XCTAssertEqual(p2.y, 40)
    }

    func testPointSum() {
        let p = Point(15, 25)
        XCTAssertEqual(p.sum, 40)
    }

    func testPointEquality() {
        let p1 = Point(10, 20)
        let p2 = Point(10, 20)
        let p3 = Point(10, 21)

        XCTAssertEqual(p1, p2)
        XCTAssertNotEqual(p1, p3)
    }

    func testPointDescription() {
        let p = Point(100, 200)
        XCTAssertEqual(p.description, "(100, 200)")
    }

    // MARK: - Segment Initialization

    func testSegmentCreation() {
        let s1 = Segment((10, 20), (30, 40))
        XCTAssertEqual(s1.a, Point(10, 20))
        XCTAssertEqual(s1.b, Point(30, 40))

        let s2 = Segment(Point(5, 10), Point(15, 20))
        XCTAssertEqual(s2.a, Point(5, 10))
        XCTAssertEqual(s2.b, Point(15, 20))
    }

    func testSegmentFromArrays() {
        let s = Segment([10, 20], [30, 40])
        XCTAssertEqual(s.a, Point(10, 20))
        XCTAssertEqual(s.b, Point(30, 40))
    }

    func testSegmentDescription() {
        let s = Segment((10, 20), (30, 40))
        XCTAssertEqual(s.description, "((10, 20), (30, 40))")
    }

    // MARK: - Distance Calculations

    func testDistX() {
        let s1 = Segment((10, 20), (30, 40))
        XCTAssertEqual(s1.distX(), 20)
        XCTAssertEqual(s1.distX(keepSign: true), 20)

        let s2 = Segment((30, 20), (10, 40))
        XCTAssertEqual(s2.distX(), 20)
        XCTAssertEqual(s2.distX(keepSign: true), -20)
    }

    func testDistY() {
        let s1 = Segment((10, 20), (30, 40))
        XCTAssertEqual(s1.distY(), 20)
        XCTAssertEqual(s1.distY(keepSign: true), 20)

        let s2 = Segment((10, 40), (30, 20))
        XCTAssertEqual(s2.distY(), 20)
        XCTAssertEqual(s2.distY(keepSign: true), -20)
    }

    func testDist() {
        // 3-4-5 right triangle
        let s1 = Segment((0, 0), (3, 4))
        XCTAssertEqual(s1.dist(), 5.0, accuracy: 0.001)

        // Horizontal segment
        let s2 = Segment((0, 0), (10, 0))
        XCTAssertEqual(s2.dist(), 10.0, accuracy: 0.001)

        // Vertical segment
        let s3 = Segment((0, 0), (0, 10))
        XCTAssertEqual(s3.dist(), 10.0, accuracy: 0.001)

        // Diagonal segment
        let s4 = Segment((0, 0), (10, 10))
        XCTAssertEqual(s4.dist(), sqrt(200.0), accuracy: 0.001)
    }

    // MARK: - Bounding Box

    func testBoundingBox() {
        let s = Segment((30, 40), (10, 20))

        XCTAssertEqual(s.left(), 10)
        XCTAssertEqual(s.top(), 20)
        XCTAssertEqual(s.right(), 30)
        XCTAssertEqual(s.bottom(), 40)
        XCTAssertEqual(s.toXYRB(), [10, 20, 30, 40])
    }

    func testCenter() {
        let s1 = Segment((0, 0), (10, 10))
        XCTAssertEqual(s1.center(), Point(5, 5))

        let s2 = Segment((10, 20), (30, 60))
        XCTAssertEqual(s2.center(), Point(20, 40))
    }

    // MARK: - Containment

    func testMayContain() {
        let s = Segment((10, 20), (30, 40))

        XCTAssertTrue(s.mayContain(Point(20, 30)))
        XCTAssertTrue(s.mayContain(Point(10, 20)))
        XCTAssertTrue(s.mayContain(Point(30, 40)))

        XCTAssertFalse(s.mayContain(Point(5, 30)))
        XCTAssertFalse(s.mayContain(Point(35, 30)))
        XCTAssertFalse(s.mayContain(Point(20, 15)))
        XCTAssertFalse(s.mayContain(Point(20, 45)))
    }

    // MARK: - Angle Calculations

    func testAngle() {
        // Horizontal segment (0°)
        let s1 = Segment((0, 0), (10, 0))
        XCTAssertEqual(s1.angle(), 0.0, accuracy: 0.001)

        // Vertical segment (90°)
        let s2 = Segment((0, 0), (0, 10))
        XCTAssertEqual(s2.angle(), .pi / 2, accuracy: 0.001)

        // 45° segment
        let s3 = Segment((0, 0), (10, 10))
        XCTAssertEqual(s3.angle(), .pi / 4, accuracy: 0.001)
    }

    func testAngleWith() {
        let horizontal = Segment((0, 0), (10, 0))
        let vertical = Segment((0, 0), (0, 10))
        let diagonal = Segment((0, 0), (10, 10))

        XCTAssertEqual(horizontal.angleWith(horizontal), 0.0, accuracy: 0.1)
        XCTAssertEqual(horizontal.angleWith(vertical), 90.0, accuracy: 0.1)
        XCTAssertEqual(horizontal.angleWith(diagonal), 45.0, accuracy: 0.1)
    }

    func testAngleOkWith() {
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, 5), (15, 5))  // Parallel
        let s3 = Segment((0, 0), (0, 10))  // Perpendicular

        XCTAssertTrue(s1.angleOkWith(s2))   // 0° difference
        XCTAssertFalse(s1.angleOkWith(s3))  // 90° difference

        // Nearly parallel (small angle)
        let s4 = Segment((0, 0), (10, 1))
        XCTAssertTrue(s1.angleOkWith(s4))

        // 180° difference (opposite direction but parallel)
        let s5 = Segment((10, 0), (0, 0))
        XCTAssertTrue(s1.angleOkWith(s5))
    }

    // MARK: - Equality

    func testSegmentEquality() {
        let s1 = Segment((10, 20), (30, 40))
        let s2 = Segment((10, 20), (30, 40))
        let s3 = Segment((30, 40), (10, 20))  // Reversed
        let s4 = Segment((10, 20), (30, 41))  // Different

        XCTAssertEqual(s1, s2)
        XCTAssertEqual(s1, s3)  // Segments are equal regardless of direction
        XCTAssertNotEqual(s1, s4)
    }

    // MARK: - Intersection

    func testIntersectOverlapping() {
        // Overlapping horizontal segments
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, 0), (15, 0))

        let intersection = s1.intersect(s2)
        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection?.a, Point(5, 0))
        XCTAssertEqual(intersection?.b, Point(10, 0))
    }

    func testIntersectContained() {
        // One segment contained in another
        let s1 = Segment((0, 0), (20, 0))
        let s2 = Segment((5, 0), (15, 0))

        let intersection = s1.intersect(s2)
        XCTAssertNotNil(intersection)
        XCTAssertEqual(intersection?.a, Point(5, 0))
        XCTAssertEqual(intersection?.b, Point(15, 0))
    }

    func testIntersectNonParallel() {
        // Perpendicular segments should not intersect (angle check fails)
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, -5), (5, 5))

        XCTAssertNil(s1.intersect(s2))
    }

    func testIntersectApart() {
        // Parallel but spatially separated
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((20, 0), (30, 0))

        XCTAssertNil(s1.intersect(s2))
    }

    func testIntersectTooFarApart() {
        // Parallel but too far apart perpendicular distance
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((0, 100), (10, 100))

        XCTAssertNil(s1.intersect(s2))
    }

    // MARK: - Union

    func testUnionOverlapping() {
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((5, 0), (15, 0))

        let union = s1.union(s2)
        XCTAssertNotNil(union)
        XCTAssertEqual(union?.a, Point(0, 0))
        XCTAssertEqual(union?.b, Point(15, 0))
    }

    func testUnionNonIntersecting() {
        let s1 = Segment((0, 0), (10, 0))
        let s2 = Segment((20, 0), (30, 0))

        XCTAssertNil(s1.union(s2))
    }

    func testUnionAll() {
        // Multiple overlapping segments
        let segments = [
            Segment((0, 0), (5, 0)),
            Segment((4, 0), (10, 0)),
            Segment((9, 0), (15, 0)),
            Segment((20, 0), (25, 0)),  // Separate segment
        ]

        let unioned = Segment.unionAll(segments)

        // Should result in two segments: one from 0-15, another from 20-25
        XCTAssertEqual(unioned.count, 2)

        // Check that we have the expected unioned segments
        let hasLongSegment = unioned.contains { s in
            (s.a == Point(0, 0) && s.b == Point(15, 0)) ||
            (s.a == Point(15, 0) && s.b == Point(0, 0))
        }
        let hasShortSegment = unioned.contains { s in
            (s.a == Point(20, 0) && s.b == Point(25, 0)) ||
            (s.a == Point(25, 0) && s.b == Point(20, 0))
        }

        XCTAssertTrue(hasLongSegment)
        XCTAssertTrue(hasShortSegment)
    }

    // MARK: - Projection

    func testProjectedPointOnSegment() {
        // Point projects onto the middle of horizontal segment
        let s = Segment((0, 0), (10, 0))
        let p = Point(5, 5)
        let projected = s.projectedPoint(p)

        XCTAssertEqual(projected, Point(5, 0))
    }

    func testProjectedPointBeyondSegment() {
        // Point beyond the segment still projects onto the line
        let s = Segment((0, 0), (10, 0))
        let p = Point(15, 5)
        let projected = s.projectedPoint(p)

        XCTAssertEqual(projected, Point(15, 0))
    }

    func testProjectedPointOnVerticalSegment() {
        let s = Segment((0, 0), (0, 10))
        let p = Point(5, 5)
        let projected = s.projectedPoint(p)

        XCTAssertEqual(projected, Point(0, 5))
    }

    func testProjectedPointOnDiagonalSegment() {
        let s = Segment((0, 0), (10, 10))
        let p = Point(10, 0)
        let projected = s.projectedPoint(p)

        // Projection should be at (5, 5)
        XCTAssertEqual(projected, Point(5, 5))
    }

    func testProjectedPointDegenerateSegment() {
        // Segment that's actually a point
        let s = Segment((5, 5), (5, 5))
        let p = Point(10, 10)
        let projected = s.projectedPoint(p)

        XCTAssertEqual(projected, Point(5, 5))
    }

    // MARK: - IntersectAll

    func testIntersectAll() {
        let s = Segment((0, 0), (20, 0))
        let segments = [
            Segment((5, 0), (10, 0)),
            Segment((8, 0), (15, 0)),
            Segment((30, 0), (40, 0)),  // No intersection
        ]

        let intersections = s.intersectAll(segments)

        // Should intersect with first two, union them into one
        XCTAssertEqual(intersections.count, 1)
        XCTAssertEqual(intersections[0].a, Point(5, 0))
        XCTAssertEqual(intersections[0].b, Point(15, 0))
    }

    // MARK: - Performance Tests

    func testSegmentCreationPerformance() {
        measure {
            for i in 0..<1000 {
                _ = Segment((i, i * 2), (i + 10, i * 2 + 10))
            }
        }
    }

    func testDistanceCalculationPerformance() {
        let segments = (0..<1000).map { i in
            Segment((i, i * 2), (i + 10, i * 2 + 10))
        }

        measure {
            for segment in segments {
                _ = segment.dist()
            }
        }
    }

    func testIntersectionPerformance() {
        let s1 = Segment((0, 0), (100, 0))
        let segments = (0..<100).map { i in
            Segment((i, 0), (i + 10, 0))
        }

        measure {
            for segment in segments {
                _ = s1.intersect(segment)
            }
        }
    }

    func testUnionAllPerformance() {
        let segments = (0..<50).map { i in
            Segment((i * 2, 0), (i * 2 + 5, 0))
        }

        measure {
            _ = Segment.unionAll(segments)
        }
    }
}
