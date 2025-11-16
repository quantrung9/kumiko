//
//  Panel.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// Protocol for page-like objects that panels belong to
///
/// This allows Panel to work without requiring the full Page implementation
/// which will be added in Phase 5.
public protocol PanelPage: AnyObject {
    /// Reading direction ("ltr" or "rtl")
    var numbering: String { get }

    /// Image size as [width, height]
    var imgSize: [Int] { get }

    /// Minimum panel size ratio
    var smallPanelRatio: Double { get }

    /// All panels on this page
    var panels: [Panel] { get set }

    /// All segments on this page (for Phase 5)
    var segments: [Segment] { get }
}

/// Represents a comic panel with geometry and operations
///
/// This class handles panel detection, comparison, overlap detection,
/// and neighbor finding for comic panel analysis.
public class Panel {
    // MARK: - Properties

    /// Reference to the page this panel belongs to
    public weak var page: PanelPage?

    /// Left edge x-coordinate
    public var x: Int

    /// Top edge y-coordinate
    public var y: Int

    /// Right edge x-coordinate
    public var r: Int

    /// Bottom edge y-coordinate
    public var b: Int

    /// Optional polygon for complex panel shapes (Phase 5)
    public var polygon: [[Point]]?

    /// Whether this panel can be split
    public var splittable: Bool

    /// Cached segments within this panel
    private var cachedSegments: [Segment]?

    // MARK: - Initialization

    /// Create a panel from XYRB coordinates
    ///
    /// - Parameters:
    ///   - page: The page this panel belongs to
    ///   - x: Left edge
    ///   - y: Top edge
    ///   - r: Right edge (not width!)
    ///   - b: Bottom edge (not height!)
    /// - Returns: A new panel
    public static func fromXYRB(page: PanelPage?, x: Int, y: Int, r: Int, b: Int) -> Panel {
        return Panel(page: page, xywh: [x, y, r - x, b - y])
    }

    /// Initialize a panel
    ///
    /// - Parameters:
    ///   - page: The page this panel belongs to
    ///   - xywh: Bounding box as [x, y, width, height]
    ///   - polygon: Optional polygon for complex shapes
    ///   - splittable: Whether this panel can be split
    public init(page: PanelPage?, xywh: [Int]? = nil, polygon: [[Point]]? = nil, splittable: Bool = true) {
        self.page = page
        self.polygon = polygon
        self.splittable = splittable

        // Determine bounding box
        let bounds: [Int]
        if let xywh = xywh {
            bounds = xywh
        } else if let polygon = polygon {
            // Calculate bounding rect from polygon (simplified, full OpenCV in Phase 4)
            bounds = Panel.boundingRectFromPolygon(polygon)
        } else {
            fatalError("Panel requires either xywh or polygon")
        }

        precondition(bounds.count == 4, "xywh must have 4 values [x, y, width, height]")

        self.x = bounds[0]
        self.y = bounds[1]
        self.r = self.x + bounds[2]
        self.b = self.y + bounds[3]
    }

    /// Calculate bounding rectangle from polygon
    ///
    /// This is a simplified version for Phase 3. Full OpenCV version in Phase 4.
    private static func boundingRectFromPolygon(_ polygon: [[Point]]) -> [Int] {
        guard !polygon.isEmpty, !polygon[0].isEmpty else {
            return [0, 0, 0, 0]
        }

        let points = polygon[0]
        let minX = points.map { $0.x }.min() ?? 0
        let minY = points.map { $0.y }.min() ?? 0
        let maxX = points.map { $0.x }.max() ?? 0
        let maxY = points.map { $0.y }.max() ?? 0

        return [minX, minY, maxX - minX, maxY - minY]
    }

    // MARK: - Geometry

    /// Panel width
    public func w() -> Int {
        return r - x
    }

    /// Panel height
    public func h() -> Int {
        return b - y
    }

    /// Panel diagonal as a segment
    public func diagonal() -> Segment {
        return Segment((x, y), (r, b))
    }

    /// Width threshold for equality comparison (10% of width)
    public func wt() -> Double {
        return Double(w()) / 10.0
    }

    /// Height threshold for equality comparison (10% of height)
    public func ht() -> Double {
        return Double(h()) / 10.0
    }

    /// Convert to XYWH array format
    public func toXYWH() -> [Int] {
        return [x, y, w(), h()]
    }

    /// Panel area in square pixels
    public func area() -> Int {
        return w() * h()
    }

    // MARK: - Size Checks

    /// Check if panel is small relative to page size
    ///
    /// - Parameter extraRatio: Multiplier for the threshold (default 1.0)
    /// - Returns: True if panel is considered small
    public func isSmall(extraRatio: Double = 1.0) -> Bool {
        guard let page = page else { return false }

        let minWidth = Double(page.imgSize[0]) * page.smallPanelRatio * extraRatio
        let minHeight = Double(page.imgSize[1]) * page.smallPanelRatio * extraRatio

        return Double(w()) < minWidth || Double(h()) < minHeight
    }

    /// Check if panel is very small (1/10th of normal threshold)
    public func isVerySmall() -> Bool {
        return isSmall(extraRatio: 1.0 / 10.0)
    }

    // MARK: - Overlap Detection

    /// Find the overlapping region with another panel
    ///
    /// - Parameter other: The other panel
    /// - Returns: A panel representing the overlap, or nil if no overlap
    public func overlapPanel(_ other: Panel) -> Panel? {
        // Check if panels are separated horizontally
        if self.x > other.r || other.x > self.r {
            return nil
        }

        // Check if panels are separated vertically
        if self.y > other.b || other.y > self.b {
            return nil
        }

        // Calculate overlap region
        let overlapX = max(self.x, other.x)
        let overlapY = max(self.y, other.y)
        let overlapR = min(self.r, other.r)
        let overlapB = min(self.b, other.b)

        return Panel(page: self.page, xywh: [overlapX, overlapY, overlapR - overlapX, overlapB - overlapY])
    }

    /// Calculate the overlapping area with another panel
    ///
    /// - Parameter other: The other panel
    /// - Returns: Area of overlap in square pixels
    public func overlapArea(_ other: Panel) -> Int {
        guard let overlap = overlapPanel(other) else {
            return 0
        }
        return overlap.area()
    }

    /// Check if this panel overlaps significantly with another
    ///
    /// Overlap is significant if it's more than 10% of the smaller panel's area
    ///
    /// - Parameter other: The other panel
    /// - Returns: True if panels overlap significantly
    public func overlaps(_ other: Panel) -> Bool {
        guard let overlap = overlapPanel(other) else {
            return false
        }

        let areaRatio = 0.1
        let smallestPanelArea = min(self.area(), other.area())

        // Handle degenerate case (zero-area panels like segments)
        if smallestPanelArea == 0 {
            return true
        }

        return Double(overlap.area()) / Double(smallestPanelArea) > areaRatio
    }

    /// Check if this panel contains another panel
    ///
    /// Contains means the overlap is more than 50% of the other panel's area
    ///
    /// - Parameter other: The other panel
    /// - Returns: True if this panel contains the other
    public func contains(_ other: Panel) -> Bool {
        guard let overlap = overlapPanel(other) else {
            return false
        }

        let otherArea = other.area()
        guard otherArea > 0 else { return false }

        return Double(overlap.area()) / Double(otherArea) > 0.50
    }

    // MARK: - Row/Column Detection

    /// Check if this panel is in the same row as another panel
    ///
    /// Panels are in the same row if their vertical overlap is >= 1/3 of the minimum height
    ///
    /// - Parameter other: The other panel
    /// - Returns: True if panels are in the same row
    public func sameRow(_ other: Panel) -> Bool {
        let panels = [self, other].sorted { $0.y < $1.y }
        let above = panels[0]
        let below = panels[1]

        // Strictly above (no overlap)
        if below.y > above.b {
            return false
        }

        // Contained
        if below.b < above.b {
            return true
        }

        // Intersect
        let intersectionY = min(above.b, below.b) - below.y
        let minH = min(above.h(), below.h())

        return minH == 0 || Double(intersectionY) / Double(minH) >= 1.0 / 3.0
    }

    /// Check if this panel is in the same column as another panel
    ///
    /// Panels are in the same column if their horizontal overlap is >= 1/3 of the minimum width
    ///
    /// - Parameter other: The other panel
    /// - Returns: True if panels are in the same column
    public func sameCol(_ other: Panel) -> Bool {
        let panels = [self, other].sorted { $0.x < $1.x }
        let left = panels[0]
        let right = panels[1]

        // Strictly left (no overlap)
        if right.x > left.r {
            return false
        }

        // Contained
        if right.r < left.r {
            return true
        }

        // Intersect
        let intersectionX = min(left.r, right.r) - right.x
        let minW = min(left.w(), right.w())

        return minW == 0 || Double(intersectionX) / Double(minW) >= 1.0 / 3.0
    }

    // MARK: - Neighbor Finding

    /// Find the panel directly above this one
    ///
    /// - Returns: The top neighbor panel, or nil if none
    public func findTopPanel() -> Panel? {
        guard let page = page else { return nil }

        let allTop = page.panels.filter { p in
            p.b <= self.y && p.sameCol(self)
        }

        return allTop.max { $0.b < $1.b }
    }

    /// Find the panel directly below this one
    ///
    /// - Returns: The bottom neighbor panel, or nil if none
    public func findBottomPanel() -> Panel? {
        guard let page = page else { return nil }

        let allBottom = page.panels.filter { p in
            p.y >= self.b && p.sameCol(self)
        }

        return allBottom.min { $0.y < $1.y }
    }

    /// Find all panels to the left of this one
    ///
    /// - Returns: Array of left panels
    public func findAllLeftPanels() -> [Panel] {
        guard let page = page else { return [] }

        return page.panels.filter { p in
            p.r <= self.x && p.sameRow(self)
        }
    }

    /// Find the panel directly to the left of this one
    ///
    /// - Returns: The left neighbor panel, or nil if none
    public func findLeftPanel() -> Panel? {
        let allLeft = findAllLeftPanels()
        return allLeft.max { $0.r < $1.r }
    }

    /// Find all panels to the right of this one
    ///
    /// - Returns: Array of right panels
    public func findAllRightPanels() -> [Panel] {
        guard let page = page else { return [] }

        return page.panels.filter { p in
            p.x >= self.r && p.sameRow(self)
        }
    }

    /// Find the panel directly to the right of this one
    ///
    /// - Returns: The right neighbor panel, or nil if none
    public func findRightPanel() -> Panel? {
        let allRight = findAllRightPanels()
        return allRight.min { $0.x < $1.x }
    }

    /// Find a neighbor panel in a given direction
    ///
    /// - Parameter direction: Direction as character ('x'=left, 'y'=top, 'r'=right, 'b'=bottom)
    /// - Returns: The neighbor panel, or nil if none
    public func findNeighborPanel(_ direction: Character) -> Panel? {
        switch direction {
        case "x": return findLeftPanel()
        case "y": return findTopPanel()
        case "r": return findRightPanel()
        case "b": return findBottomPanel()
        default: return nil
        }
    }

    // MARK: - Panel Operations

    /// Create a panel that groups this panel with another
    ///
    /// Returns the bounding box that contains both panels
    ///
    /// - Parameter other: The other panel
    /// - Returns: A new panel containing both
    public func groupWith(_ other: Panel) -> Panel {
        let minX = min(self.x, other.x)
        let minY = min(self.y, other.y)
        let maxR = max(self.r, other.r)
        let maxB = max(self.b, other.b)

        return Panel(page: self.page, xywh: [minX, minY, maxR - minX, maxB - minY])
    }

    /// Merge this panel with another, expanding in all directions
    ///
    /// Tries multiple expansion options and returns the largest that doesn't
    /// overlap with other panels on the page.
    ///
    /// - Parameter other: The other panel to merge with
    /// - Returns: The merged panel
    public func merge(_ other: Panel) -> Panel {
        var possiblePanels: [Panel] = [self]

        // Expand self in all four directions where other extends
        if other.x < self.x {
            possiblePanels.append(Panel.fromXYRB(page: self.page, x: other.x, y: self.y, r: self.r, b: self.b))
        }

        if other.r > self.r {
            for pp in possiblePanels {
                possiblePanels.append(Panel.fromXYRB(page: self.page, x: pp.x, y: pp.y, r: other.r, b: pp.b))
            }
        }

        if other.y < self.y {
            for pp in possiblePanels {
                possiblePanels.append(Panel.fromXYRB(page: self.page, x: pp.x, y: other.y, r: pp.r, b: pp.b))
            }
        }

        if other.b > self.b {
            for pp in possiblePanels {
                possiblePanels.append(Panel.fromXYRB(page: self.page, x: pp.x, y: pp.y, r: pp.r, b: other.b))
            }
        }

        // Filter out panels that bump into other panels
        guard let page = page else { return self }
        let otherPanels = page.panels.filter { p in
            p !== self && p !== other
        }

        let validPanels = possiblePanels.filter { !$0.bumpsInto(otherPanels) }

        // Return the largest valid panel
        return validPanels.max { $0.area() < $1.area() } ?? self
    }

    /// Check if this panel's center is close to another panel's center
    ///
    /// Close means the distance is <= 75% of the sum of dimensions
    ///
    /// - Parameter other: The other panel
    /// - Returns: True if panels are close
    public func isClose(_ other: Panel) -> Bool {
        let c1x = Double(self.x) + Double(self.w()) / 2.0
        let c1y = Double(self.y) + Double(self.h()) / 2.0
        let c2x = Double(other.x) + Double(other.w()) / 2.0
        let c2y = Double(other.y) + Double(other.h()) / 2.0

        let maxDistX = (Double(self.w()) + Double(other.w())) * 0.75
        let maxDistY = (Double(self.h()) + Double(other.h())) * 0.75

        return abs(c1x - c2x) <= maxDistX && abs(c1y - c2y) <= maxDistY
    }

    /// Check if this panel bumps into any of the given panels
    ///
    /// - Parameter otherPanels: Array of panels to check against
    /// - Returns: True if this panel overlaps with any of them
    public func bumpsInto(_ otherPanels: [Panel]) -> Bool {
        for other in otherPanels {
            if self === other {
                continue
            }
            if self.overlaps(other) {
                return true
            }
        }
        return false
    }

    /// Check if this panel contains a segment
    ///
    /// - Parameter segment: The segment to check
    /// - Returns: True if the segment is within this panel
    public func containsSegment(_ segment: Segment) -> Bool {
        let segmentBounds = segment.toXYRB()
        let segmentPanel = Panel.fromXYRB(
            page: nil,
            x: segmentBounds[0],
            y: segmentBounds[1],
            r: segmentBounds[2],
            b: segmentBounds[3]
        )
        return self.overlaps(segmentPanel)
    }

    /// Get all segments within this panel (cached)
    ///
    /// - Returns: Array of segments
    public func getSegments() -> [Segment] {
        if let cached = cachedSegments {
            return cached
        }

        guard let page = page else {
            cachedSegments = []
            return []
        }

        let segments = page.segments.filter { self.containsSegment($0) }
        cachedSegments = segments
        return segments
    }

    // MARK: - Splitting (Stub for Phase 5)

    /// Attempt to split this panel
    ///
    /// This is a stub for Phase 3. Full implementation requires OpenCV (Phase 4-5).
    ///
    /// - Returns: Split result if successful, or nil
    public func split() -> Split? {
        // TODO: Implement in Phase 5 with OpenCV and polygon support
        return nil
    }
}

// MARK: - Equatable

extension Panel: Equatable {
    public static func == (lhs: Panel, rhs: Panel) -> Bool {
        return abs(lhs.x - rhs.x) < Int(lhs.wt()) &&
               abs(lhs.y - rhs.y) < Int(lhs.ht()) &&
               abs(lhs.r - rhs.r) < Int(lhs.wt()) &&
               abs(lhs.b - rhs.b) < Int(lhs.ht())
    }
}

// MARK: - Comparable

extension Panel: Comparable {
    /// Compare panels for sorting (reading order)
    ///
    /// Panels are sorted by:
    /// 1. Vertical position (top to bottom)
    /// 2. Horizontal position (left to right, or right to left for RTL)
    public static func < (lhs: Panel, rhs: Panel) -> Bool {
        let ht = lhs.ht()

        // Panel is above other
        if rhs.y >= lhs.b - Int(ht) && rhs.y >= lhs.y - Int(ht) {
            return true
        }

        // Panel is below other
        if lhs.y >= rhs.b - Int(ht) && lhs.y >= rhs.y - Int(ht) {
            return false
        }

        let wt = lhs.wt()
        let isLTR = lhs.page?.numbering == "ltr"

        // Panel is left from other
        if rhs.x >= lhs.r - Int(wt) && rhs.x >= lhs.x - Int(wt) {
            return isLTR
        }

        // Panel is right from other
        if lhs.x >= rhs.r - Int(wt) && lhs.x >= rhs.x - Int(wt) {
            return !isLTR
        }

        return true
    }
}

// MARK: - Hashable

extension Panel: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(description)
    }
}

// MARK: - CustomStringConvertible

extension Panel: CustomStringConvertible {
    public var description: String {
        return "\(x)x\(y)-\(r)x\(b)"
    }
}

// MARK: - Split Result (Stub for Phase 5)

/// Result of splitting a panel
///
/// This is a placeholder for Phase 5. Full implementation requires
/// polygon processing with OpenCV.
public struct Split {
    public let panel: Panel
    public let subpanels: [Panel]
    public let segment: Segment

    public init(panel: Panel, subpanels: [Panel], segment: Segment) {
        self.panel = panel
        self.subpanels = subpanels
        self.segment = segment
    }
}
