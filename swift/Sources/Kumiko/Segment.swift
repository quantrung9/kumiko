//
//  Segment.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// A 2D point with integer coordinates
public struct Point: Equatable, Hashable, Sendable {
    public let x: Int
    public let y: Int

    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }

    public init(_ tuple: (Int, Int)) {
        self.x = tuple.0
        self.y = tuple.1
    }

    /// Sum of coordinates (used for sorting)
    public var sum: Int {
        return x + y
    }
}

extension Point: CustomStringConvertible {
    public var description: String {
        return "(\(x), \(y))"
    }
}

/// A line segment defined by two points
///
/// Represents a geometric line segment with various operations including
/// distance calculations, angle measurements, and intersection detection.
public struct Segment: Equatable, Hashable, Sendable {
    /// First endpoint of the segment
    public let a: Point

    /// Second endpoint of the segment
    public let b: Point

    /// Initialize a segment from two points
    ///
    /// - Parameters:
    ///   - a: First point (any type convertible to integers)
    ///   - b: Second point (any type convertible to integers)
    public init(_ a: (Int, Int), _ b: (Int, Int)) {
        self.a = Point(a)
        self.b = Point(b)
    }

    /// Initialize a segment from Point instances
    public init(_ a: Point, _ b: Point) {
        self.a = a
        self.b = b
    }

    /// Initialize from array-like structures (for compatibility)
    public init<T: BinaryInteger>(_ a: [T], _ b: [T]) {
        precondition(a.count == 2, "Point a must have exactly 2 coordinates")
        precondition(b.count == 2, "Point b must have exactly 2 coordinates")
        self.a = Point(Int(a[0]), Int(a[1]))
        self.b = Point(Int(b[0]), Int(b[1]))
    }

    // MARK: - Distance Calculations

    /// Total distance of the segment (Euclidean distance)
    public func dist() -> Double {
        let dx = distX()
        let dy = distY()
        return sqrt(Double(dx * dx + dy * dy))
    }

    /// Horizontal distance (absolute or signed)
    ///
    /// - Parameter keepSign: If true, preserves sign (negative if a.x > b.x)
    /// - Returns: Horizontal distance between endpoints
    public func distX(keepSign: Bool = false) -> Int {
        let dist = b.x - a.x
        return keepSign ? dist : abs(dist)
    }

    /// Vertical distance (absolute or signed)
    ///
    /// - Parameter keepSign: If true, preserves sign (negative if a.y > b.y)
    /// - Returns: Vertical distance between endpoints
    public func distY(keepSign: Bool = false) -> Int {
        let dist = b.y - a.y
        return keepSign ? dist : abs(dist)
    }

    // MARK: - Bounding Box

    /// Leftmost x-coordinate of the segment
    public func left() -> Int {
        return min(a.x, b.x)
    }

    /// Topmost y-coordinate of the segment
    public func top() -> Int {
        return min(a.y, b.y)
    }

    /// Rightmost x-coordinate of the segment
    public func right() -> Int {
        return max(a.x, b.x)
    }

    /// Bottommost y-coordinate of the segment
    public func bottom() -> Int {
        return max(a.y, b.y)
    }

    /// Bounding box in [x, y, right, bottom] format
    public func toXYRB() -> [Int] {
        return [left(), top(), right(), bottom()]
    }

    /// Center point of the segment
    public func center() -> Point {
        let x = Int(left() + distX() / 2)
        let y = Int(top() + distY() / 2)
        return Point(x, y)
    }

    // MARK: - Containment

    /// Check if a point might be contained within the segment's bounding box
    ///
    /// - Parameter point: The point to check
    /// - Returns: True if the point is within the bounding box
    public func mayContain(_ point: Point) -> Bool {
        return point.x >= left() &&
               point.x <= right() &&
               point.y >= top() &&
               point.y <= bottom()
    }

    // MARK: - Angle Calculations

    /// Angle of the segment in radians
    ///
    /// - Returns: Angle from horizontal, in range [0, π/2]
    public func angle() -> Double {
        let dx = distX()
        let dy = distY()
        return dx != 0 ? atan(Double(dy) / Double(dx)) : .pi / 2
    }

    /// Angle difference with another segment in degrees
    ///
    /// - Parameter other: The other segment
    /// - Returns: Absolute angle difference in degrees
    public func angleWith(_ other: Segment) -> Double {
        let diff = abs(self.angle() - other.angle())
        return diff * 180.0 / .pi
    }

    /// Check if two segments are nearly parallel
    ///
    /// Segments are considered parallel if their angle difference is < 10° or > 170°
    ///
    /// - Parameter other: The other segment
    /// - Returns: True if segments are nearly parallel
    public func angleOkWith(_ other: Segment) -> Bool {
        let angle = angleWith(other)
        return angle < 10 || abs(angle - 180) < 10
    }

    // MARK: - Intersection

    /// Find the intersection of two segments
    ///
    /// This method checks if two segments overlap when considering them
    /// as nearly parallel line segments with a small tolerance (gutter).
    ///
    /// - Parameter other: The other segment
    /// - Returns: The intersecting segment, or nil if no intersection
    public func intersect(_ other: Segment) -> Segment? {
        let gutter = max(self.dist(), other.dist()) * 5.0 / 100.0

        // Check if angles are compatible (nearly parallel)
        guard self.angleOkWith(other) else {
            return nil
        }

        // Check if segments are spatially apart
        if Double(self.right()) < Double(other.left()) - gutter ||  // self left from other
           Double(self.left()) > Double(other.right()) + gutter ||  // self right from other
           Double(self.bottom()) < Double(other.top()) - gutter ||  // self above other
           Double(self.top()) > Double(other.bottom()) + gutter {   // self below other
            return nil
        }

        // Check perpendicular distance between segments
        let projectedC = self.projectedPoint(other.a)
        let distCtoAB = Segment(other.a, projectedC).dist()

        let projectedD = self.projectedPoint(other.b)
        let distDtoAB = Segment(other.b, projectedD).dist()

        if (distCtoAB + distDtoAB) / 2.0 > gutter {
            return nil
        }

        // Find overlapping portion
        // Sort all four points and take the middle two
        let allDots = [self.a, self.b, other.a, other.b].sorted { $0.sum < $1.sum }
        let middleDots = Array(allDots[1...2])

        return Segment(middleDots[0], middleDots[1])
    }

    /// Intersect this segment with multiple segments and union the results
    ///
    /// - Parameter segments: Array of segments to intersect with
    /// - Returns: Array of unioned intersecting segments
    public func intersectAll(_ segments: [Segment]) -> [Segment] {
        let matches = segments.compactMap { self.intersect($0) }
        return Segment.unionAll(matches)
    }

    // MARK: - Union

    /// Union two segments if they intersect
    ///
    /// - Parameter other: The other segment
    /// - Returns: The combined segment, or nil if segments don't intersect
    public func union(_ other: Segment) -> Segment? {
        guard let intersection = self.intersect(other) else {
            return nil
        }

        // Collect all four endpoints
        var dots: Set<Point> = [self.a, self.b, other.a, other.b]

        // Remove the intersection endpoints
        dots.remove(intersection.a)
        dots.remove(intersection.b)

        // The remaining two points form the union
        let remaining = Array(dots)
        guard remaining.count == 2 else {
            return nil
        }

        return Segment(remaining[0], remaining[1])
    }

    /// Union multiple segments iteratively
    ///
    /// This static method repeatedly unions overlapping segments until
    /// no more unions are possible.
    ///
    /// - Parameter segments: Array of segments to union
    /// - Returns: Array of maximally unioned segments
    public static func unionAll(_ segments: [Segment]) -> [Segment] {
        var currentSegments = segments
        var didUnion = true

        while didUnion {
            didUnion = false
            var dedupSegments: [Segment] = []
            var used: Set<Int> = []

            for i in 0..<currentSegments.count {
                if used.contains(i) {
                    continue
                }

                var wasUnioned = false
                for j in (i + 1)..<currentSegments.count {
                    if used.contains(j) {
                        continue
                    }

                    if let unioned = currentSegments[i].union(currentSegments[j]) {
                        didUnion = true
                        wasUnioned = true
                        dedupSegments.append(unioned)
                        used.insert(i)
                        used.insert(j)
                        break
                    }
                }

                if !wasUnioned && !used.contains(i) {
                    dedupSegments.append(currentSegments[i])
                    used.insert(i)
                }
            }

            currentSegments = dedupSegments
        }

        return currentSegments
    }

    // MARK: - Projection

    /// Project a point onto this segment
    ///
    /// Calculates the orthogonal projection of a point onto the infinite line
    /// defined by this segment, then returns the nearest point.
    ///
    /// This uses the formula: projection = a + ((p-a)·(b-a) / |b-a|²) * (b-a)
    ///
    /// - Parameter point: The point to project
    /// - Returns: The projected point on the segment's line
    public func projectedPoint(_ point: Point) -> Point {
        // Handle degenerate case (segment is a point)
        if a == b {
            return a
        }

        // Vector from a to b
        let abX = Double(b.x - a.x)
        let abY = Double(b.y - a.y)

        // Vector from a to p
        let apX = Double(point.x - a.x)
        let apY = Double(point.y - a.y)

        // Dot products
        let apDotAb = apX * abX + apY * abY
        let abDotAb = abX * abX + abY * abY

        // Prevent division by zero (already handled above, but extra safety)
        guard abDotAb != 0 else {
            return a
        }

        // Scalar projection
        let t = apDotAb / abDotAb

        // Projected point
        let projX = Double(a.x) + t * abX
        let projY = Double(a.y) + t * abY

        return Point(Int(round(projX)), Int(round(projY)))
    }

    // MARK: - Polygon Helper

    /// Extend a segment along a polygon's edges
    ///
    /// Starting from edge (i, j) of a polygon, this method extends the segment
    /// by walking along the polygon edges in both directions as long as the
    /// edges are nearly parallel with the current segment.
    ///
    /// - Parameters:
    ///   - polygon: Array of points forming a polygon (each point is [x, y])
    ///   - i: Starting index
    ///   - j: Ending index
    /// - Returns: Extended segment
    public static func alongPolygon(_ polygon: [[Point]], _ i: Int, _ j: Int) -> Segment {
        var currentI = i
        var currentJ = j
        let n = polygon.count

        let dot1 = polygon[i][0]
        let dot2 = polygon[j][0]
        var splitSegment = Segment(dot1, dot2)

        // Extend backwards from i
        while true {
            currentI = (currentI - 1 + n) % n
            let addSegment = Segment(
                polygon[currentI][0],
                polygon[(currentI + 1) % n][0]
            )

            if addSegment.angleOkWith(splitSegment) {
                splitSegment = Segment(addSegment.a, splitSegment.b)
            } else {
                break
            }
        }

        // Extend forwards from j
        while true {
            currentJ = (currentJ + 1) % n
            let addSegment = Segment(
                polygon[(currentJ - 1 + n) % n][0],
                polygon[currentJ][0]
            )

            if addSegment.angleOkWith(splitSegment) {
                splitSegment = Segment(splitSegment.a, addSegment.b)
            } else {
                break
            }
        }

        return splitSegment
    }
}

// MARK: - CustomStringConvertible

extension Segment: CustomStringConvertible {
    public var description: String {
        return "(\(a), \(b))"
    }
}
