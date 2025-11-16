//
//  PanelInfo.swift
//  Kumiko
//
//  Swift port of Kumiko comic panel detection
//  Original Python version: https://github.com/njean42/kumiko
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

import Foundation

/// Represents a single comic panel with its location and dimensions
///
/// Panels are represented in XYWH format: [x, y, width, height]
/// where (x, y) is the top-left corner coordinate.
public struct PanelInfo: Equatable, Sendable {
    /// X-coordinate of the panel's left edge
    public let x: Int

    /// Y-coordinate of the panel's top edge
    public let y: Int

    /// Width of the panel in pixels
    public let width: Int

    /// Height of the panel in pixels
    public let height: Int

    /// Right edge coordinate (computed)
    public var right: Int {
        return x + width
    }

    /// Bottom edge coordinate (computed)
    public var bottom: Int {
        return y + height
    }

    /// Panel area in square pixels
    public var area: Int {
        return width * height
    }

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    /// Initialize from XYWH array format
    public init(xywh: [Int]) {
        guard xywh.count == 4 else {
            fatalError("PanelInfo requires exactly 4 values [x, y, width, height]")
        }
        self.x = xywh[0]
        self.y = xywh[1]
        self.width = xywh[2]
        self.height = xywh[3]
    }

    /// Convert to XYWH array format for JSON serialization
    public func toXYWH() -> [Int] {
        return [x, y, width, height]
    }

    /// Initialize from XYRB (x, y, right, bottom) format
    public static func fromXYRB(x: Int, y: Int, right: Int, bottom: Int) -> PanelInfo {
        return PanelInfo(
            x: x,
            y: y,
            width: right - x,
            height: bottom - y
        )
    }
}

extension PanelInfo: CustomStringConvertible {
    public var description: String {
        return "\(x)x\(y)-\(right)x\(bottom)"
    }
}
