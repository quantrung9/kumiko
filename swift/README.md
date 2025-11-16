# Kumiko Swift

Swift port of [Kumiko](https://github.com/njean42/kumiko), the comic panel detection tool.

## Status: Phase 2 - Geometry Module Complete ✅

This is an in-progress port of Kumiko from Python to Swift. The implementation follows a 13-week roadmap detailed in [SWIFT_PORTING_PLAN.md](../SWIFT_PORTING_PLAN.md).

### Current Progress

| Phase | Status | Description |
|-------|--------|-------------|
| **Phase 1** | ✅ **Complete** | Foundation & project setup |
| **Phase 2** | ✅ **Complete** | Geometry module (Segment) |
| Phase 3 | ⏳ Pending | Panel operations |
| Phase 4 | ⏳ Pending | OpenCV integration |
| Phase 5 | ⏳ Pending | Page analysis algorithm |
| Phase 6 | ⏳ Pending | Main Kumiko class |
| Phase 7 | ⏳ Pending | Debug & HTML generation |
| Phase 8 | ⏳ Pending | CLI tool |
| Phase 9 | ⏳ Pending | Testing & validation |
| Phase 10 | ⏳ Pending | Documentation & polish |

### Phase 1 Deliverables ✅

- ✅ Swift Package Manager structure
- ✅ Basic data models (PageInfo, PanelInfo, ProcessingOptions)
- ✅ Command-line interface skeleton with ArgumentParser
- ✅ Unit test framework
- ✅ Buildable package

### Phase 2 Deliverables ✅

- ✅ Complete Segment class (~450 lines, pure Swift)
- ✅ Point structure for 2D coordinates
- ✅ All geometric operations (distance, angles, intersection, union)
- ✅ NumPy operations replaced with native Swift math
- ✅ 54 comprehensive unit tests
- ✅ Python compatibility validation suite
- ✅ 100% feature parity with Python lib/segment.py

## Requirements

- **Swift 5.9+** (for Swift-C++ interop support)
- **macOS 13+** or **Linux** (Ubuntu 20.04+)
- **OpenCV** (to be integrated in Phase 4)

## Building

```bash
cd swift
swift build
```

## Testing

```bash
swift test
```

## Running (Skeleton Only)

```bash
swift run kumiko-cli -i /path/to/image.jpg
```

**Note**: The CLI currently only demonstrates the argument parsing structure. Actual panel detection will be implemented in Phases 2-8.

## Project Structure

```
swift/
├── Package.swift                    # Swift Package Manager manifest
├── README.md                        # This file
├── PHASE1_CHECKLIST.md             # Phase 1 completion tracking
├── PHASE2_CHECKLIST.md             # Phase 2 completion tracking
├── Sources/
│   ├── Kumiko/                     # Library module
│   │   ├── Kumiko.swift           # Main class (skeleton)
│   │   ├── Segment.swift          # ✅ Geometric segment operations
│   │   └── Models/                # Data models
│   │       ├── PageInfo.swift     # Page information structure
│   │       ├── PanelInfo.swift    # Panel information structure
│   │       └── ProcessingOptions.swift  # Configuration options
│   └── kumiko-cli/                # Executable module
│       └── main.swift             # CLI entry point
└── Tests/
    └── KumikoTests/
        ├── KumikoTests.swift           # Basic unit tests
        ├── SegmentTests.swift          # ✅ Segment geometry tests (39 tests)
        └── PythonCompatibilityTests.swift  # ✅ Python parity tests (15 tests)
```

## Architecture

### Library Module (`Kumiko`)

The library is designed as a reusable framework that can be:
- Imported by other Swift projects
- Used programmatically for batch processing
- Extended for iOS/macOS app integration

### CLI Module (`kumiko-cli`)

Command-line interface matching the Python version's functionality:
- Single image processing
- Directory batch processing
- PDF support (via subprocess)
- JSON and HTML output
- Browser integration

## Development Roadmap

See [SWIFT_PORTING_PLAN.md](../SWIFT_PORTING_PLAN.md) for the complete 13-week implementation plan.

### Next Steps (Phase 3)

Phase 3 will implement the `Panel` class for panel detection operations:
- Panel bounding box and geometry
- Overlap and containment detection
- Panel comparison and sorting (Comparable protocol)
- Neighbor finding algorithms
- Panel merging and grouping logic
- Minimal OpenCV usage (boundingRect only)

**Estimated completion**: 1 week (~550 lines)

## Contributing

This port maintains compatibility with the original Python version. All contributions should:

1. Follow the phased roadmap
2. Include unit tests
3. Match Python output for equivalent operations
4. Follow Swift API Design Guidelines
5. Maintain AGPL-3.0 license compatibility

## Testing Strategy

- **Unit Tests**: For individual classes and functions
- **Integration Tests**: For complete workflows
- **Regression Tests**: Against Python version output
- **Performance Tests**: Benchmarking vs Python

Target: 80%+ code coverage

## License

This Swift port is licensed under **AGPL-3.0**, matching the original Python version.

```
Kumiko, the Comics Cutter
Copyright (C) 2024

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.
```

## Credits

- **Original Python version**: [njean42/kumiko](https://github.com/njean42/kumiko)
- **Swift port**: In progress as of 2024

## Documentation

- [SWIFT_PORTING_PLAN.md](../SWIFT_PORTING_PLAN.md) - Complete porting roadmap
- API documentation will be generated with DocC in Phase 10

## Platform Support

| Platform | Library | CLI | Status |
|----------|---------|-----|--------|
| macOS | ✅ | ✅ | Phase 2 complete |
| Linux | ✅ | ✅ | Phase 2 complete |
| iOS | 🟡 | ❌ | Future consideration |
| Windows | ❌ | ❌ | Not planned |

## FAQ

### Why Swift?

- Native performance (comparable or better than Python)
- Strong type safety
- Modern language features (async/await, protocols, generics)
- Excellent tooling (Xcode, SwiftPM, DocC)
- Cross-platform support (macOS, Linux, iOS)
- Growing ecosystem for computer vision

### Will the Python version be deprecated?

No. Both versions will be maintained in parallel. The Python version remains the canonical implementation.

### When will this be production-ready?

Target: 13 weeks from Phase 1 start (see roadmap). A beta release is expected after Phase 9 (testing & validation).

### Can I use this now?

Phase 1 provides the foundation but no actual panel detection yet. Check back after Phase 5 for a functional prototype.

## Contact

For issues, questions, or contributions related to the Swift port, please use the main repository's issue tracker.
