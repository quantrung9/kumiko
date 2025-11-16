//
//  main.swift
//  kumiko-cli
//
//  Swift port of Kumiko comic panel detection CLI
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import ArgumentParser
import Foundation
import Kumiko

/// Kumiko CLI tool for comic panel detection
///
/// This command-line tool detects panels in comic book pages and outputs
/// their locations as JSON or HTML. Full implementation in Phase 8.
@main
struct KumikoCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "kumiko",
        abstract: "Comic panel detection tool",
        discussion: """
            Kumiko analyzes comic book pages to detect panel locations.
            It can process individual images, directories, or PDF files.

            Example usage:
              kumiko -i page.jpg                    # Analyze a single page
              kumiko -i comic/                      # Analyze all images in directory
              kumiko -i page.jpg -o output.json     # Save to JSON file
              kumiko -i page.jpg -b firefox         # Open in browser

            This is the Swift port of Kumiko. Phase 1 foundation complete.
            Full implementation coming in phases 2-10.
            """
    )

    @Option(name: .shortAndLong, help: "Input image file or directory")
    var input: String

    @Option(name: .shortAndLong, help: "Output file path (JSON or HTML)")
    var output: String?

    @Flag(name: .long, help: "Use right-to-left reading order")
    var rtl: Bool = false

    @Flag(name: .long, help: "Generate HTML output")
    var html: Bool = false

    @Flag(name: .shortAndLong, help: "Enable debug mode")
    var debug: Bool = false

    @Flag(name: .long, help: "Show progress information")
    var progress: Bool = false

    @Flag(name: .long, help: "Disable panel expansion")
    var noPanelExpansion: Bool = false

    @Option(name: .long, help: "Minimum panel size ratio (default: 0.1)")
    var minPanelSizeRatio: Double?

    mutating func run() throws {
        print("Kumiko Swift - Phase 1 Foundation")
        print("==================================")
        print()
        print("Input: \(input)")
        print("Options:")
        print("  RTL: \(rtl)")
        print("  Debug: \(debug)")
        print("  Progress: \(progress)")
        print("  Panel expansion: \(!noPanelExpansion)")
        if let ratio = minPanelSizeRatio {
            print("  Min panel ratio: \(ratio)")
        }
        print()

        // Create processing options
        let options = ProcessingOptions(
            debug: debug,
            progress: progress,
            rtl: rtl,
            minPanelSizeRatio: minPanelSizeRatio,
            panelExpansion: !noPanelExpansion
        )

        // Initialize Kumiko
        let kumiko = Kumiko(options: options)

        // TODO: Actual processing will be implemented in later phases
        print("⚠️  Full implementation coming in Phase 5-8")
        print("📋 Phase 1 Status: Foundation complete ✅")
        print("📋 Phase 2-4: Segment, Panel, OpenCV integration (pending)")
        print("📋 Phase 5: Page analysis (pending)")
        print("📋 Phase 8: CLI completion (pending)")
        print()
        print("Current capabilities:")
        print("  ✅ Swift package structure")
        print("  ✅ Command-line argument parsing")
        print("  ✅ Data models (PageInfo, PanelInfo)")
        print("  ✅ Processing options")
        print("  ⏳ Image processing (Phase 4-5)")
        print("  ⏳ Panel detection (Phase 3-5)")
        print()

        // For now, just demonstrate the structure
        if output != nil {
            print("Output will be written to: \(output!)")
        }
    }
}
