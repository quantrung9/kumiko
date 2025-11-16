//
//  PageInfo.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// Represents complete information about a comic page
///
/// This structure contains all detected panel information for a single page,
/// including metadata like processing time and gutters.
public struct PageInfo: Codable, Equatable, Sendable {
    /// The filename or URL of the page image
    public let filename: String

    /// Image dimensions as [width, height]
    public let size: [Int]

    /// Reading direction: "ltr" (left-to-right) or "rtl" (right-to-left)
    public let numbering: String

    /// Gutter spacing between panels as [x, y]
    public let gutters: [Int]

    /// Optional license information for the page
    public let license: LicenseInfo?

    /// Array of detected panels in [x, y, width, height] format
    public let panels: [[Int]]

    /// Time taken to process this page (in seconds)
    public let processingTime: Double?

    public init(
        filename: String,
        size: [Int],
        numbering: String,
        gutters: [Int],
        license: LicenseInfo? = nil,
        panels: [[Int]],
        processingTime: Double? = nil
    ) {
        self.filename = filename
        self.size = size
        self.numbering = numbering
        self.gutters = gutters
        self.license = license
        self.panels = panels
        self.processingTime = processingTime
    }

    enum CodingKeys: String, CodingKey {
        case filename
        case size
        case numbering
        case gutters
        case license
        case panels
        case processingTime = "processing_time"
    }
}

/// License information for a comic page
///
/// Matches the structure from .license JSON files
public struct LicenseInfo: Codable, Equatable, Sendable {
    /// Title or name of the work
    public let title: String?

    /// Author/creator name
    public let author: String?

    /// License type (e.g., "CC BY 4.0")
    public let license: String?

    /// URL to the original work
    public let url: String?

    public init(
        title: String? = nil,
        author: String? = nil,
        license: String? = nil,
        url: String? = nil
    ) {
        self.title = title
        self.author = author
        self.license = license
        self.url = url
    }
}
