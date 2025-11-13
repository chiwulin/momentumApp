# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modern iOS application built with SwiftUI targeting iOS 18.5+. The project uses Xcode 16.4 with Swift 5.0 and follows Apple's modern app lifecycle patterns. This is currently a minimal template app ready for feature development.

**Key Details:**
- Bundle ID: Justin.momentum
- Universal app (iPhone and iPad)
- No external dependencies (pure Apple frameworks)
- Uses modern Swift Testing framework for unit tests and XCTest for UI tests

## Common Commands

### Building

```bash
# Build for iOS Simulator (Debug)
xcodebuild -project momentum.xcodeproj -scheme momentum -configuration Debug -sdk iphonesimulator

# Build for Release
xcodebuild -project momentum.xcodeproj -scheme momentum -configuration Release -sdk iphoneos
```

### Testing

```bash
# Run all tests
xcodebuild test -project momentum.xcodeproj -scheme momentum -destination 'platform=iOS Simulator,name=iPhone 16'

# Run only unit tests (Swift Testing framework)
xcodebuild test -project momentum.xcodeproj -scheme momentum -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:momentumTests

# Run only UI tests (XCTest framework)
xcodebuild test -project momentum.xcodeproj -scheme momentum -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:momentumUITests

# Run a specific test
xcodebuild test -project momentum.xcodeproj -scheme momentum -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:momentumTests/momentumTests/testExample
```

### Running the App

```bash
# Open in Xcode
open momentum.xcodeproj

# Build and run via command line
xcodebuild -project momentum.xcodeproj -scheme momentum -destination 'platform=iOS Simulator,name=iPhone 16' run
```

## Architecture

### App Structure

The project follows SwiftUI's modern app lifecycle pattern:

- **momentumApp.swift**: Entry point using `@main` attribute and `App` protocol. Defines the root WindowGroup with ContentView.
- **ContentView.swift**: Main view. Currently displays a simple "Hello, world!" interface with SwiftUI preview support.

### Testing Structure

**Unit Tests** (`momentumTests/`):
- Uses modern Swift Testing framework with `@Test` attribute
- Supports async/throws patterns
- Example: `momentumTests.swift`

**UI Tests** (`momentumUITests/`):
- Uses XCTest framework with XCUIApplication
- Includes launch tests that capture screenshots
- Example: `momentumUITests.swift`, `momentumUITestsLaunchTests.swift`

### Key Frameworks

- **SwiftUI**: Declarative UI framework (no UIKit/Storyboards)
- **Swift Testing**: Modern unit testing framework
- **XCTest/XCUITest**: Traditional testing frameworks for UI tests

## Build Configuration

**Debug Configuration:**
- Optimization: None (-Onone)
- Testability enabled
- Full debug symbols

**Release Configuration:**
- Whole module optimization
- Product validation enabled
- Debug symbols: dwarf-with-dsym

**Important Build Settings:**
- Deployment Target: iOS 18.5
- Swift Version: 5.0
- Automatic code signing enabled
- User script sandboxing enabled
- Parallel build enabled

## Development Notes

### Current State

This is a freshly generated template app with minimal implementation. The codebase is ready for feature development but currently only contains:
- Basic "Hello World" UI
- Template test files
- Standard asset catalog with app icon and accent color

### Adding New Features

When adding features to this app:

1. **SwiftUI Views**: Create new SwiftUI view files in the `momentum/` directory. Follow the pattern in ContentView.swift with `#Preview` macros for previews.

2. **Unit Tests**: Add new test files in `momentumTests/` using the Swift Testing framework (`@Test` attribute). Tests should be async/throws where appropriate.

3. **UI Tests**: Add UI test cases in `momentumUITests/` using XCUIApplication. Follow the pattern in existing UI test files.

4. **Assets**: Add images, colors, and other assets to `momentum/Assets.xcassets/`.

5. **Dependencies**: If external dependencies are needed, use Swift Package Manager (SPM) via Xcode's File > Add Package Dependencies menu.

### File Organization

The project uses Xcode 16's modern PBXFileSystemSynchronizedRootGroup, which automatically syncs files with the file system. When adding new files:
- Place Swift source files in `momentum/` for app code
- Place unit tests in `momentumTests/`
- Place UI tests in `momentumUITests/`
- Xcode will automatically include them in the appropriate targets

### Testing Guidelines

- Unit tests use Swift Testing framework: Use `@Test` attribute instead of XCTest's `func testXYZ()` pattern
- UI tests use XCTest: Use `XCTestCase` subclasses with `func testXYZ()` methods
- Launch tests capture screenshots for visual regression testing
- Performance tests are available via `measure { }` blocks in UI tests
