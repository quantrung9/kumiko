//
//  Kumiko.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// Main Kumiko class for comic panel detection
///
/// This class orchestrates the panel detection process for images, directories,
/// PDFs, and URL lists. It will be fully implemented in Phase 6.
public final class Kumiko {
    /// Processing options
    public let options: ProcessingOptions

    /// List of processed pages
    private(set) var pages: [PageInfo] = []

    /// Initialize Kumiko with processing options
    ///
    /// - Parameter options: Configuration for panel detection
    public init(options: ProcessingOptions = .default) {
        self.options = options
    }

    /// Parse a single image file
    ///
    /// - Parameter imagePath: Path to the image file
    /// - Throws: If the image cannot be loaded or processed
    public func parseImage(_ imagePath: String) throws {
        // TODO: Implement in Phase 5
        throw KumikoError.notImplemented("parseImage will be implemented in Phase 5")
    }

    /// Parse all images in a directory
    ///
    /// - Parameter directoryPath: Path to the directory
    /// - Throws: If the directory cannot be read
    public func parseDirectory(_ directoryPath: String) throws {
        // TODO: Implement in Phase 6
        throw KumikoError.notImplemented("parseDirectory will be implemented in Phase 6")
    }

    /// Get information about all processed pages
    ///
    /// - Returns: Array of page information
    public func getInfo() -> [PageInfo] {
        return pages
    }
}

/// Errors that can occur during Kumiko processing
public enum KumikoError: Error, LocalizedError {
    case notImplemented(String)
    case invalidImage(String)
    case invalidDirectory(String)
    case processingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not yet implemented: \(message)"
        case .invalidImage(let path):
            return "Invalid or unreadable image: \(path)"
        case .invalidDirectory(let path):
            return "Invalid or unreadable directory: \(path)"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}
