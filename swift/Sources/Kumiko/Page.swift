//
//  Page.swift
//  Kumiko
//
//  Swift port of Kumiko comic page analysis
//  Original Python version: https://github.com/njean42/kumiko/lib/page.py
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation
import OpenCVBridge

/// Errors that can occur during page processing
public enum PageError: Error {
    case notAnImage(String)
    case imageLoadFailed(String)
    case contourDetectionFailed
    case invalidNumbering(String)
    case processingFailed(String)
}

/// Page class - main panel detection and analysis
///
/// This class implements the complete panel detection pipeline:
/// 1. Load image and convert to grayscale
/// 2. Apply Sobel edge detection
/// 3. Detect contours from thresholded Sobel image
/// 4. Detect line segments using LSD
/// 5. Create initial panels from contours
/// 6. Group small adjacent panels
/// 7. Split panels using detected segments
/// 8. Merge and de-overlap panels
/// 9. Expand panels into gutters (optional)
/// 10. Fix panel reading order
public class Page: PanelPage {
    // MARK: - Constants

    public static let defaultMinPanelSizeRatio = 1.0 / 10.0

    // MARK: - Properties

    /// Image file path
    public let filename: String

    /// Original BGR color image
    private var img: OpenCVBridge.ImageData?

    /// Grayscale image
    private var gray: OpenCVBridge.ImageData?

    /// Sobel-filtered image
    private var sobel: OpenCVBridge.ImageData?

    /// Detected contours from thresholded Sobel image
    private var contours: [[OpenCVBridge.Point]] = []

    // MARK: - PanelPage Protocol Properties

    /// Image size as [width, height]
    public var imgSize: [Int]

    /// Reading direction ("ltr" or "rtl")
    public var numbering: String

    /// Detected panels (implements PanelPage)
    public var panels: [Panel] = []

    /// Detected line segments (implements PanelPage)
    public var segments: [Segment] = []

    /// Minimum panel size ratio (implements PanelPage)
    public var smallPanelRatio: Double

    // MARK: - Additional Properties

    /// Whether to expand panels into gutters
    public let panelExpansion: Bool

    /// Processing time in seconds
    public var processingTime: Double?

    /// Optional URL for web sources
    public let url: String?

    /// Optional license information
    public var license: LicenseInfo?

    // MARK: - Initialization

    /// Initialize a Page from an image file
    ///
    /// - Parameters:
    ///   - filename: Path to image file
    ///   - numbering: Reading direction ("ltr" or "rtl"), default "ltr"
    ///   - debug: Enable debug mode (future use)
    ///   - url: Optional URL for web sources
    ///   - minPanelSizeRatio: Minimum panel size as ratio of image, default 1/10
    ///   - panelExpansion: Whether to expand panels into gutters, default true
    /// - Throws: PageError if image cannot be loaded or processing fails
    public init(
        filename: String,
        numbering: String? = nil,
        debug: Bool = false,
        url: String? = nil,
        minPanelSizeRatio: Double? = nil,
        panelExpansion: Bool = true
    ) throws {
        let startTime = Date()

        self.filename = filename
        self.url = url
        self.panelExpansion = panelExpansion

        // Validate and set numbering
        let num = numbering ?? "ltr"
        guard num == "ltr" || num == "rtl" else {
            throw PageError.invalidNumbering(num)
        }
        self.numbering = num

        // Set panel size ratio
        self.smallPanelRatio = minPanelSizeRatio ?? Page.defaultMinPanelSizeRatio

        // Initialize imgSize (will be set after image load)
        self.imgSize = [0, 0]

        // Load image
        let imgResult = OpenCVBridge.loadImage(filename)
        guard imgResult.success else {
            throw PageError.notAnImage(filename)
        }

        self.img = imgResult.value
        self.imgSize = [Int(img!.width), Int(img!.height)]

        // Load license file if exists
        self.license = try? self.loadLicense()

        // Run processing pipeline
        try self.processImage()

        self.processingTime = Date().timeIntervalSince(startTime)
    }

    // MARK: - License Loading

    private func loadLicense() throws -> LicenseInfo {
        let licensePath = filename + ".license"

        guard FileManager.default.fileExists(atPath: licensePath) else {
            throw PageError.processingFailed("No license file")
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: licensePath))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return try decoder.decode(LicenseInfo.self, from: data)
    }

    // MARK: - Processing Pipeline

    private func processImage() throws {
        // 1. Convert to grayscale
        guard let img = self.img else {
            throw PageError.processingFailed("No image loaded")
        }

        self.gray = OpenCVBridge.cvtColor(
            img,
            Int32(OpenCVBridge.ColorConversion.BGR2GRAY.rawValue)
        )

        // 2. Apply Sobel edge detection
        try self.applySobel()

        // 3. Get contours from thresholded Sobel image
        try self.getContours()

        // 4. Get line segments using LSD
        try self.getSegments()

        // 5. Get initial panels from contours
        self.getInitialPanels()

        // 6. Group small adjacent panels
        self.groupSmallPanels()

        // 7. Split panels using segments
        self.splitPanels()

        // 8. Exclude small panels
        self.excludeSmallPanels()

        // 9. Merge panels that contain each other
        self.mergePanels()

        // 10. De-overlap panels
        self.deoverlapPanels()

        // 11. Exclude small panels again
        self.excludeSmallPanels()

        // 12. Expand panels into gutters (optional)
        if self.panelExpansion {
            self.panels.sort()
            self.expandPanels()
        }

        // 13. Add default panel if none detected
        if self.panels.isEmpty {
            self.panels.append(Panel(
                page: self,
                xywh: [0, 0, self.imgSize[0], self.imgSize[1]]
            ))
        }

        // 14. Group big panels
        self.groupBigPanels()

        // 15. Fix panel numbering (reading order)
        self.fixPanelsNumbering()
    }

    // MARK: - Image Processing Methods

    /// Apply Sobel edge detection
    ///
    /// Computes gradients in X and Y directions, converts to absolute values,
    /// and combines them with equal weight.
    private func applySobel() throws {
        guard let gray = self.gray else {
            throw PageError.processingFailed("No grayscale image")
        }

        // Gradient X (dx=1, dy=0)
        let gradX = OpenCVBridge.sobel(gray, 1, 0)
        let absGradX = OpenCVBridge.convertScaleAbs(gradX)

        // Gradient Y (dx=0, dy=1)
        let gradY = OpenCVBridge.sobel(gray, 0, 1)
        let absGradY = OpenCVBridge.convertScaleAbs(gradY)

        // Combine gradients: 0.5 * absGradX + 0.5 * absGradY
        self.sobel = OpenCVBridge.addWeighted(
            absGradX, 0.5,
            absGradY, 0.5,
            0.0
        )
    }

    /// Detect contours from thresholded Sobel image
    ///
    /// Applies binary threshold at 100, then finds external contours.
    private func getContours() throws {
        guard let sobel = self.sobel else {
            throw PageError.processingFailed("No Sobel image")
        }

        // Binary threshold: values above 100 become white (255), rest black (0)
        let threshResult = OpenCVBridge.threshold(
            sobel,
            100.0,  // threshold value
            255.0,  // max value
            Int32(OpenCVBridge.ThresholdType.BINARY.rawValue)
        )

        guard threshResult.success else {
            throw PageError.contourDetectionFailed
        }

        // Find external contours with simple approximation
        self.contours = OpenCVBridge.findContours(
            threshResult.value,
            Int32(OpenCVBridge.RetrievalMode.EXTERNAL.rawValue),
            Int32(OpenCVBridge.ApproximationMethod.SIMPLE.rawValue)
        )
    }

    /// Detect line segments using Line Segment Detector
    ///
    /// Uses adaptive threshold to limit segments to ~500 maximum.
    private func getSegments() throws {
        guard let gray = self.gray else {
            throw PageError.processingFailed("No grayscale image")
        }

        var segments: [Segment]? = nil
        var minDist = Double(min(imgSize[0], imgSize[1])) * smallPanelRatio

        let lines = OpenCVBridge.detectLineSegments(gray)

        // Adaptive filtering to limit segments to ~500
        while segments == nil || segments!.count > 500 {
            segments = []

            for line in lines {
                let dx = Double(line.start.x - line.end.x)
                let dy = Double(line.start.y - line.end.y)
                let dist = sqrt(dx * dx + dy * dy)

                if dist >= minDist {
                    segments!.append(Segment(
                        (Int(line.start.x), Int(line.start.y)),
                        (Int(line.end.x), Int(line.end.y))
                    ))
                }
            }

            minDist *= 1.1  // Increase threshold to reduce count
        }

        // Union overlapping segments
        self.segments = Segment.unionAll(segments!)
    }

    // MARK: - Panel Detection Methods

    /// Create initial panels from detected contours
    ///
    /// Approximates each contour as a polygon and creates a Panel.
    /// Very small panels are filtered out.
    private func getInitialPanels() {
        self.panels = []

        for contour in contours {
            // Calculate arc length
            let arcLen = OpenCVBridge.arcLength(contour, true)

            // Approximate polygon with epsilon = 0.1% of arc length
            let epsilon = 0.001 * arcLen
            let approx = OpenCVBridge.approxPolyDP(contour, epsilon, true)

            // Convert to Point array for Panel
            let polygon = [approx.map { Point(x: Int($0.x), y: Int($0.y)) }]

            let panel = Panel(page: self, polygon: polygon)

            // Skip very small panels
            if panel.isVerySmall() {
                continue
            }

            self.panels.append(panel)
        }
    }

    /// Group small adjacent panels into larger ones
    ///
    /// Python implementation uses complex grouping logic.
    /// This is a simplified version that merges touching small panels.
    private func groupSmallPanels() {
        let smallPanels = panels.filter { $0.isSmall() }

        if smallPanels.isEmpty {
            return
        }

        var groups: [Int: Set<Panel>] = [:]
        var panelToGroup: [ObjectIdentifier: Int] = [:]
        var nextGroupId = 0

        // Find adjacent small panels
        for (i, p1) in smallPanels.enumerated() {
            for p2 in smallPanels[(i+1)...] {
                guard p1 !== p2 else { continue }

                if p1.isClose(p2) {
                    let p1Id = ObjectIdentifier(p1)
                    let p2Id = ObjectIdentifier(p2)

                    let group1 = panelToGroup[p1Id]
                    let group2 = panelToGroup[p2Id]

                    if let g1 = group1, let g2 = group2 {
                        // Merge groups
                        if g1 != g2 {
                            groups[g1]!.formUnion(groups[g2]!)
                            for panel in groups[g2]! {
                                panelToGroup[ObjectIdentifier(panel)] = g1
                            }
                            groups[g2] = nil
                        }
                    } else if let g1 = group1 {
                        // Add p2 to group1
                        groups[g1]!.insert(p2)
                        panelToGroup[p2Id] = g1
                    } else if let g2 = group2 {
                        // Add p1 to group2
                        groups[g2]!.insert(p1)
                        panelToGroup[p1Id] = g2
                    } else {
                        // Create new group
                        groups[nextGroupId] = [p1, p2]
                        panelToGroup[p1Id] = nextGroupId
                        panelToGroup[p2Id] = nextGroupId
                        nextGroupId += 1
                    }
                }
            }
        }

        // Merge panels in each group
        for (_, groupPanels) in groups {
            guard let groupPanels = groupPanels, !groupPanels.isEmpty else { continue }

            // Calculate bounding box of all panels in group
            var minX = Int.max
            var minY = Int.max
            var maxR = Int.min
            var maxB = Int.min

            for panel in groupPanels {
                minX = min(minX, panel.x)
                minY = min(minY, panel.y)
                maxR = max(maxR, panel.r)
                maxB = max(maxB, panel.b)
            }

            // Create merged panel
            let mergedPanel = Panel.fromXYRB(
                page: self,
                x: minX,
                y: minY,
                r: maxR,
                b: maxB
            )

            // Remove original panels and add merged one
            for panel in groupPanels {
                panels.removeAll { $0 === panel }
            }
            panels.append(mergedPanel)
        }
    }

    /// Split panels using detected line segments
    ///
    /// Iteratively splits largest panels until no more splits are possible.
    private func splitPanels() {
        var didSplit = true

        while didSplit {
            didSplit = false

            // Sort panels by area (largest first)
            let sortedPanels = panels.sorted { $0.area() > $1.area() }

            for panel in sortedPanels {
                if let splitResult = panel.split() {
                    didSplit = true

                    // Remove original panel
                    panels.removeAll { $0 === panel }

                    // Add subpanels
                    panels.append(contentsOf: splitResult.subpanels)

                    break  // Restart with new panel set
                }
            }
        }
    }

    /// Remove panels that are too small
    private func excludeSmallPanels() {
        panels.removeAll { $0.isSmall() }
    }

    /// Merge panels where one contains the other
    ///
    /// Handles cases like speech bubbles within panels.
    private func mergePanels() {
        var panelsToRemove: Set<Panel> = []

        for (i, p1) in panels.enumerated() {
            for p2 in panels[(i+1)...] {
                if p1.contains(p2) {
                    panelsToRemove.insert(p2)
                    // Merge p2 into p1 (expand p1's bounding box)
                    let merged = p1.merge(p2)
                    p1.x = merged.x
                    p1.y = merged.y
                    p1.r = merged.r
                    p1.b = merged.b
                } else if p2.contains(p1) {
                    panelsToRemove.insert(p1)
                    // Merge p1 into p2
                    let merged = p2.merge(p1)
                    p2.x = merged.x
                    p2.y = merged.y
                    p2.r = merged.r
                    p2.b = merged.b
                }
            }
        }

        // Remove contained panels
        for panel in panelsToRemove {
            panels.removeAll { $0 === panel }
        }
    }

    /// De-overlap panels by adjusting their edges
    ///
    /// Splitting polygons may create slightly overlapping panels.
    /// This adjusts edges to remove overlaps.
    private func deoverlapPanels() {
        for p1 in panels {
            for p2 in panels {
                guard p1 !== p2 else { continue }

                guard let opanel = p1.overlapPanel(p2) else {
                    continue
                }

                // Vertical overlap - adjust horizontal edges
                if opanel.w() < opanel.h() && p1.r == opanel.r {
                    p1.r = opanel.x
                    p2.x = opanel.r
                    continue
                }

                // Horizontal overlap - adjust vertical edges
                if opanel.w() > opanel.h() && p1.b == opanel.b {
                    p1.b = opanel.y
                    p2.y = opanel.b
                    continue
                }
            }
        }
    }

    /// Expand panels into gutters (space between panels)
    ///
    /// Only called if panelExpansion is true.
    private func expandPanels() {
        let gutters = actualGutters()
        let gutterX = gutters.x
        let gutterY = gutters.y

        for panel in panels {
            var expansionX = gutterX / 2
            var expansionY = gutterY / 2

            // Check if expansion would overlap with neighbors
            if let leftPanel = panel.findLeftPanel() {
                expansionX = min(expansionX, (panel.x - leftPanel.r) / 2)
            }
            if let rightPanel = panel.findRightPanel() {
                expansionX = min(expansionX, (rightPanel.x - panel.r) / 2)
            }
            if let topPanel = panel.findTopPanel() {
                expansionY = min(expansionY, (panel.y - topPanel.b) / 2)
            }
            if let bottomPanel = panel.findBottomPanel() {
                expansionY = min(expansionY, (bottomPanel.y - panel.b) / 2)
            }

            // Expand panel bounds
            panel.x = max(0, panel.x - expansionX)
            panel.y = max(0, panel.y - expansionY)
            panel.r = min(imgSize[0], panel.r + expansionX)
            panel.b = min(imgSize[1], panel.b + expansionY)
        }
    }

    /// Fix panel numbering to match reading order
    ///
    /// Ensures panels are sorted correctly for LTR or RTL reading.
    private func fixPanelsNumbering() {
        // Panels are already Comparable, so sort() uses their < operator
        // which handles reading order based on numbering (ltr/rtl)
        panels.sort()
    }

    /// Group large panels (future feature)
    ///
    /// Python implementation groups panels, but functionality is minimal.
    private func groupBigPanels() {
        // TODO: Implement if needed based on Python version
        // Currently a placeholder
    }

    // MARK: - Helper Methods

    /// Calculate actual gutters between panels
    ///
    /// - Parameter func: Aggregation function (min, max, avg)
    /// - Returns: Gutter sizes as (x: horizontal, y: vertical)
    public func actualGutters(
        func aggregator: ([Int]) -> Int = { $0.min() ?? 0 }
    ) -> (x: Int, y: Int) {
        var guttersX: [Int] = []
        var guttersY: [Int] = []

        for panel in panels {
            if let leftPanel = panel.findLeftPanel() {
                guttersX.append(panel.x - leftPanel.r)
            }
            if let topPanel = panel.findTopPanel() {
                guttersY.append(panel.y - topPanel.b)
            }
        }

        let gutterX = guttersX.isEmpty ? 0 : aggregator(guttersX)
        let gutterY = guttersY.isEmpty ? 0 : aggregator(guttersY)

        return (x: gutterX, y: gutterY)
    }

    /// Get maximum gutter size
    public func maxGutter() -> (x: Int, y: Int) {
        return actualGutters(func: { $0.max() ?? 0 })
    }

    // MARK: - Output

    /// Get page information for JSON output
    ///
    /// Matches Python's get_infos() output format.
    public func getInfo() -> PageInfo {
        let gutters = actualGutters()

        return PageInfo(
            filename: url ?? URL(fileURLWithPath: filename).lastPathComponent,
            size: imgSize,
            numbering: numbering,
            gutters: [gutters.x, gutters.y],
            license: license,
            panels: panels.map { $0.toXYWH() },
            processingTime: processingTime
        )
    }
}
