# COpenCV - System Library Module

This is a system library target that links to OpenCV installed on your system via a package manager.

## Installation

### macOS

```bash
# Install OpenCV via Homebrew
brew install opencv

# Verify installation
pkg-config --modversion opencv4
```

### Linux (Ubuntu/Debian)

```bash
# Install OpenCV development libraries
sudo apt-get update
sudo apt-get install libopencv-dev

# Verify installation
pkg-config --modversion opencv4
```

### Linux (Fedora/RHEL)

```bash
# Install OpenCV development libraries
sudo dnf install opencv-devel

# Verify installation
pkg-config --modversion opencv4
```

## Module Map Configuration

The `module.modulemap` file in this directory tells Swift how to import OpenCV C++ headers. The header paths are platform-specific:

- **macOS (Intel)**: `/usr/local/include/opencv4/`
- **macOS (Apple Silicon)**: `/opt/homebrew/include/opencv4/`
- **Linux (Ubuntu)**: `/usr/include/opencv4/`

The Swift Package Manager uses `pkg-config` to automatically find the correct paths for your system.

## Troubleshooting

### Error: "Package opencv4 was not found"

**Solution 1:** Check if OpenCV is installed:
```bash
pkg-config --list-all | grep opencv
```

**Solution 2:** If you see `opencv` instead of `opencv4`, your system has OpenCV 3.x. Install OpenCV 4.x:
```bash
# macOS
brew upgrade opencv

# Linux
sudo apt-get install libopencv-dev
```

**Solution 3:** Check pkg-config search paths:
```bash
echo $PKG_CONFIG_PATH
```

### Error: "Header not found"

If the module map cannot find headers, you may need to update the paths in `module.modulemap`:

```bash
# Find your OpenCV installation
pkg-config --variable=includedir opencv4

# Update module.modulemap with the correct path
```

### Error: "Unsupported C++ standard library"

OpenCV requires C++11 or later. Ensure your Swift toolchain supports C++ interop (Swift 5.9+).

## Module Contents

This module provides access to:
- **opencv_core** - Core functionality (matrices, basic operations)
- **opencv_imgproc** - Image processing (contours, bounding rects)
- **opencv_imgcodecs** - Image I/O (loading/saving images)

Additional OpenCV modules can be added by updating the `module.modulemap` and linker settings in `Package.swift`.
