//
//  ProcessingOptions.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// Configuration options for Kumiko panel detection
public struct ProcessingOptions: Sendable {
    /// Enable debug output and image generation
    public let debug: Bool

    /// Print progress information to stderr
    public let progress: Bool

    /// Use right-to-left reading order
    public let rtl: Bool

    /// Minimum panel size ratio relative to image dimensions
    /// Default is 1/10 (panels smaller than 10% of image are excluded)
    public let minPanelSizeRatio: Double?

    /// Enable panel expansion to fill gutters
    public let panelExpansion: Bool

    /// Default reading direction
    public var numbering: String {
        return rtl ? "rtl" : "ltr"
    }

    public init(
        debug: Bool = false,
        progress: Bool = false,
        rtl: Bool = false,
        minPanelSizeRatio: Double? = nil,
        panelExpansion: Bool = true
    ) {
        self.debug = debug
        self.progress = progress
        self.rtl = rtl
        self.minPanelSizeRatio = minPanelSizeRatio
        self.panelExpansion = panelExpansion
    }

    /// Create options from a dictionary (for testing/compatibility)
    public init(dictionary: [String: Any]) {
        self.debug = dictionary["debug"] as? Bool ?? false
        self.progress = dictionary["progress"] as? Bool ?? false
        self.rtl = dictionary["rtl"] as? Bool ?? false
        self.minPanelSizeRatio = dictionary["min_panel_size_ratio"] as? Double
        self.panelExpansion = dictionary["panel_expansion"] as? Bool ?? true
    }
}

extension ProcessingOptions {
    /// Default options matching Python implementation
    public static let `default` = ProcessingOptions()

    /// Options for debugging with visual output
    public static let debugMode = ProcessingOptions(
        debug: true,
        progress: true,
        panelExpansion: true
    )

    /// Options for right-to-left manga
    public static let manga = ProcessingOptions(rtl: true)
}
