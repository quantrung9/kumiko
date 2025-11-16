//
//  MatFileIO.h
//  Kumiko OpenCV Bridge
//
//  Simplified file I/O helper for opencv2.framework on macOS
//  Uses NSImage as intermediary for maximum compatibility
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class Mat;

NS_ASSUME_NONNULL_BEGIN

/// Helper class for loading/saving Mat objects from/to files on macOS
///
/// opencv2.framework provides Mat, Imgproc, Core classes for Swift.
/// This helper adds file I/O using NSImage as an intermediary.
@interface MatFileIO : NSObject

/// Load image from file using NSImage, then convert to Mat
/// @param path File path to image
/// @return Mat object or nil if load fails
+ (Mat * _Nullable)loadFrom:(NSString *)path;

/// Convert Mat to NSImage and save to file
/// @param mat Mat object to save
/// @param path File path for output
/// @return YES if successful, NO otherwise
+ (BOOL)save:(Mat *)mat to:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
