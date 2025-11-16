//
//  KumikoTests.swift
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

/// Basic tests for the Kumiko framework
///
/// Phase 1: Foundation tests
/// More comprehensive tests will be added in later phases
final class KumikoTests: XCTestCase {

    // MARK: - ProcessingOptions Tests

    func testDefaultOptions() {
        let options = ProcessingOptions.default

        XCTAssertFalse(options.debug)
        XCTAssertFalse(options.progress)
        XCTAssertFalse(options.rtl)
        XCTAssertTrue(options.panelExpansion)
        XCTAssertNil(options.minPanelSizeRatio)
        XCTAssertEqual(options.numbering, "ltr")
    }

    func testRTLOptions() {
        let options = ProcessingOptions.manga

        XCTAssertTrue(options.rtl)
        XCTAssertEqual(options.numbering, "rtl")
    }

    func testDebugOptions() {
        let options = ProcessingOptions.debugMode

        XCTAssertTrue(options.debug)
        XCTAssertTrue(options.progress)
    }

    func testCustomOptions() {
        let options = ProcessingOptions(
            debug: true,
            progress: true,
            rtl: true,
            minPanelSizeRatio: 0.15,
            panelExpansion: false
        )

        XCTAssertTrue(options.debug)
        XCTAssertTrue(options.progress)
        XCTAssertTrue(options.rtl)
        XCTAssertEqual(options.minPanelSizeRatio, 0.15)
        XCTAssertFalse(options.panelExpansion)
    }

    // MARK: - PanelInfo Tests

    func testPanelInfoInit() {
        let panel = PanelInfo(x: 10, y: 20, width: 100, height: 150)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.width, 100)
        XCTAssertEqual(panel.height, 150)
        XCTAssertEqual(panel.right, 110)
        XCTAssertEqual(panel.bottom, 170)
        XCTAssertEqual(panel.area, 15000)
    }

    func testPanelInfoFromXYWH() {
        let panel = PanelInfo(xywh: [10, 20, 100, 150])

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.width, 100)
        XCTAssertEqual(panel.height, 150)
    }

    func testPanelInfoToXYWH() {
        let panel = PanelInfo(x: 10, y: 20, width: 100, height: 150)
        let xywh = panel.toXYWH()

        XCTAssertEqual(xywh, [10, 20, 100, 150])
    }

    func testPanelInfoFromXYRB() {
        let panel = PanelInfo.fromXYRB(x: 10, y: 20, right: 110, bottom: 170)

        XCTAssertEqual(panel.x, 10)
        XCTAssertEqual(panel.y, 20)
        XCTAssertEqual(panel.width, 100)
        XCTAssertEqual(panel.height, 150)
    }

    func testPanelInfoDescription() {
        let panel = PanelInfo(x: 10, y: 20, width: 100, height: 150)
        XCTAssertEqual(panel.description, "10x20-110x170")
    }

    // MARK: - PageInfo Tests

    func testPageInfoCodable() throws {
        let pageInfo = PageInfo(
            filename: "test.jpg",
            size: [800, 1200],
            numbering: "ltr",
            gutters: [10, 15],
            license: nil,
            panels: [[0, 0, 400, 600], [400, 0, 400, 600]],
            processingTime: 1.23
        )

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let jsonData = try encoder.encode(pageInfo)

        // Decode back
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(PageInfo.self, from: jsonData)

        XCTAssertEqual(decoded.filename, "test.jpg")
        XCTAssertEqual(decoded.size, [800, 1200])
        XCTAssertEqual(decoded.numbering, "ltr")
        XCTAssertEqual(decoded.gutters, [10, 15])
        XCTAssertEqual(decoded.panels.count, 2)
        XCTAssertEqual(decoded.processingTime, 1.23)
    }

    func testPageInfoWithLicense() throws {
        let license = LicenseInfo(
            title: "Test Comic",
            author: "Test Author",
            license: "CC BY 4.0",
            url: "https://example.com"
        )

        let pageInfo = PageInfo(
            filename: "test.jpg",
            size: [800, 1200],
            numbering: "ltr",
            gutters: [10, 15],
            license: license,
            panels: [],
            processingTime: nil
        )

        XCTAssertNotNil(pageInfo.license)
        XCTAssertEqual(pageInfo.license?.title, "Test Comic")
        XCTAssertEqual(pageInfo.license?.author, "Test Author")
    }

    // MARK: - Kumiko Class Tests

    func testKumikoInit() {
        let kumiko = Kumiko()
        XCTAssertEqual(kumiko.pages.count, 0)
    }

    func testKumikoWithOptions() {
        let options = ProcessingOptions(debug: true, rtl: true)
        let kumiko = Kumiko(options: options)

        XCTAssertTrue(kumiko.options.debug)
        XCTAssertTrue(kumiko.options.rtl)
    }

    func testKumikoGetInfo() {
        let kumiko = Kumiko()
        let info = kumiko.getInfo()

        XCTAssertEqual(info.count, 0)
    }

    // MARK: - Performance Tests

    func testPanelInfoPerformance() {
        measure {
            for i in 0..<1000 {
                let panel = PanelInfo(x: i, y: i * 2, width: 100, height: 150)
                _ = panel.area
                _ = panel.toXYWH()
            }
        }
    }
}
