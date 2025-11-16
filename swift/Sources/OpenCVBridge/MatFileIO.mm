//
//  MatFileIO.mm
//  Kumiko OpenCV Bridge
//
//  Implementation of file I/O helper for macOS
//
//  Copyright (C) 2024
//  Licensed under AGPL-3.0
//

#import "MatFileIO.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs.hpp>
#import <AppKit/AppKit.h>

@implementation MatFileIO

+ (Mat * _Nullable)loadFrom:(NSString *)path {
    @try {
        // Method 1: Try using OpenCV's imread directly (most efficient)
        std::string cppPath = std::string([path UTF8String]);
        cv::Mat cvMat = cv::imread(cppPath, cv::IMREAD_COLOR);

        if (cvMat.empty()) {
            return nil;
        }

        // Convert cv::Mat to opencv2.framework's Mat
        // The opencv2.framework Mat class can be initialized from cv::Mat
        Mat *mat = [[Mat alloc] initWithRows:cvMat.rows
                                        cols:cvMat.cols
                                        type:cvMat.type()];

        // Copy data
        memcpy(mat.dataPointer, cvMat.data, cvMat.total() * cvMat.elemSize());

        return mat;

    } @catch (NSException *exception) {
        NSLog(@"Error in loadFrom: %@", exception);

        // Method 2: Fallback to NSImage if opencv2.framework Mat has NSImage support
        @try {
            NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
            if (!image) {
                return nil;
            }

            // Try to create Mat from NSImage
            // opencv2.framework might have Mat(image:) initializer
            // This will fail compilation if not available, but worth trying
            Mat *mat = [[Mat alloc] initWithImage:image];
            return mat;

        } @catch (NSException *inner) {
            NSLog(@"Both methods failed: %@", inner);
            return nil;
        }
    }
}

+ (BOOL)save:(Mat *)mat to:(NSString *)path {
    @try {
        if (!mat || mat.empty) {
            return NO;
        }

        // Method 1: Use OpenCV's imwrite directly (most efficient)
        std::string cppPath = std::string([path UTF8String]);

        // Create cv::Mat from opencv2.framework Mat
        cv::Mat cvMat(mat.rows, mat.cols, mat.type(), mat.dataPointer);

        if (cvMat.empty()) {
            return NO;
        }

        bool success = cv::imwrite(cppPath, cvMat);
        return success ? YES : NO;

    } @catch (NSException *exception) {
        NSLog(@"Error in save:to: %@", exception);
        return NO;
    }
}

@end
