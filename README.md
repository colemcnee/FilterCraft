# FilterCraft

[![CI](https://github.com/filtercraft/filtercraft/workflows/CI/badge.svg)](https://github.com/filtercraft/filtercraft/actions/workflows/ci.yml)
[![Release](https://github.com/filtercraft/filtercraft/workflows/Release/badge.svg)](https://github.com/filtercraft/filtercraft/actions/workflows/release.yml)
[![codecov](https://codecov.io/gh/filtercraft/filtercraft/branch/main/graph/badge.svg)](https://codecov.io/gh/filtercraft/filtercraft)
[![SwiftLint](https://img.shields.io/badge/SwiftLint-passing-brightgreen.svg)](https://github.com/realm/SwiftLint)
[![Platform](https://img.shields.io/badge/platform-iOS%2016.0%2B%20%7C%20macOS%2012.0%2B-lightgrey.svg)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A professional multi-platform photo editing application built with SwiftUI, featuring advanced image processing, filter effects, and comprehensive CI/CD pipeline.

## ✨ Features

- **🎨 Advanced Filters**: Professional-grade image filters including vintage, dramatic, monochrome, and more
- **⚙️ Precise Adjustments**: Fine-tune brightness, contrast, saturation, exposure, highlights, shadows, warmth, and tint
- **🌐 Cross-Platform**: Native iOS and macOS applications with shared core functionality
- **🔍 Transparent Filter System**: See exactly what each filter does to your adjustments
- **📱 Modern UI**: Clean, intuitive SwiftUI interface with platform-specific optimizations
- **🚀 Performance**: Optimized Core Image pipeline with real-time preview
- **📊 Session Analytics**: Track editing operations and performance metrics

## 🏗️ Architecture

FilterCraft uses a clean, modular architecture:

```
FilterCraft/
├── Apps/
│   ├── FilterCraft-iOS/          # iOS application
│   └── FilterCraft-macOS/         # macOS application
├── Packages/
│   └── FilterCraftCore/           # Shared business logic
├── .github/workflows/             # CI/CD pipelines
├── Scripts/                       # Development tools
└── fastlane/                      # Build automation
```

### Core Components

- **FilterCraftCore**: Swift Package with shared image processing, filter logic, and business rules
- **EditSession**: Centralized state management for editing operations
- **Transparent Filter System**: Separates base adjustments (from filters) and user adjustments
- **Component Architecture**: Modular SwiftUI views with single responsibilities

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+** with iOS 16.0+ and macOS 12.0+ SDKs
- **macOS 13.0+** for development
- **Homebrew** for development tools

### Quick Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/filtercraft/filtercraft.git
   cd filtercraft
   ```

2. **Run setup script**
   ```bash
   ./Scripts/setup.sh
   ```
   This installs all dependencies, generates Xcode projects, and sets up development tools.

3. **Open in Xcode**
   ```bash
   open FilterCraft.xcworkspace
   ```

4. **Build and run**
   - Select `FilterCraft-iOS` or `FilterCraft-macOS` scheme
   - Choose your target device/simulator
   - Press ⌘+R to build and run

### Manual Setup

If you prefer manual setup:

```bash
# Install development tools
brew install swiftlint fastlane xcodegen pre-commit

# Generate Xcode projects
cd Apps/FilterCraft-iOS && xcodegen generate && cd ../..
cd Apps/FilterCraft-macOS && xcodegen generate && cd ../..

# Install pre-commit hooks
pre-commit install

# Test the setup
./Scripts/test.sh
```

## 🛠️ Development

### Available Scripts

- **`./Scripts/setup.sh`** - Complete development environment setup
- **`./Scripts/build.sh`** - Build all targets (supports --ios, --macos, --release, --archive)
- **`./Scripts/test.sh`** - Run comprehensive test suite (supports --coverage, --performance)
- **`./Scripts/lint.sh`** - Code quality checks (supports --fix, --strict)

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Follow existing code patterns and conventions
   - Write tests for new functionality
   - Update documentation as needed

3. **Test your changes**
   ```bash
   ./Scripts/test.sh --coverage
   ./Scripts/lint.sh --fix
   ./Scripts/build.sh --release
   ```

4. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**
   - Use conventional commit format in PR title
   - Fill out the PR template
   - Ensure all CI checks pass

### Code Style

We use [SwiftLint](https://github.com/realm/SwiftLint) for consistent code style:

- **Line length**: 120 characters (warning), 150 (error)
- **Function length**: 50 lines (warning), 100 (error)
- **Type length**: 300 lines (warning), 500 (error)
- **Explicit access control**: Required for all declarations
- **No force unwrapping**: Use optional binding or nil coalescing
- **Documentation**: Required for public APIs

See [.swiftlint.yml](.swiftlint.yml) for complete configuration.

## 🔄 CI/CD Pipeline

FilterCraft includes a comprehensive CI/CD pipeline built with GitHub Actions:

### Continuous Integration (`ci.yml`)

Runs on every push and pull request:

- **🧪 Multi-platform testing**: iOS and macOS across multiple Xcode versions
- **📦 Swift Package tests**: Comprehensive FilterCraftCore testing
- **🔍 Code quality**: SwiftLint, security scanning, complexity analysis
- **⚡ Performance benchmarking**: Automated performance regression detection
- **📊 Code coverage**: Tracking and reporting via Codecov

### Release Automation (`release.yml`)

Triggered by version tags (e.g., `v1.0.0`):

- **🏗️ Multi-platform builds**: Automated iOS and macOS release builds
- **📝 Release notes**: Auto-generated changelogs from commit history
- **📦 Artifact management**: Signed builds ready for distribution
- **🔖 Version management**: Automated versioning and tagging

### Pull Request Validation (`pr-checks.yml`)

Ensures quality before merge:

- **📋 PR validation**: Title format, description completeness
- **🔀 Conflict detection**: Early merge conflict identification
- **🤖 Automated code review**: Pattern detection and best practice enforcement
- **📏 Size analysis**: Large PR detection and recommendations

### Build Matrix

Our CI tests across multiple configurations:

| Platform | Xcode Versions | Simulators/Targets |
|----------|---------------|-------------------|
| iOS | 15.0, 15.1 | iPhone 14, iPhone 15 |
| macOS | 15.0, 15.1 | macOS 13.0, 14.0 |
| Swift Package | System Default | Linux-compatible |

## 🚢 Deployment

### Using Fastlane

Build and deploy with Fastlane:

```bash
# Build iOS for TestFlight
fastlane ios build_release
fastlane ios deploy_testflight

# Build macOS for distribution
fastlane mac build_release
fastlane mac notarize

# Run full CI locally
fastlane ci

# Create release builds
fastlane release version:1.0.0
```

### Manual Release Process

1. **Update version numbers**
   ```bash
   fastlane update_version version:1.0.0
   ```

2. **Create and push tag**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

3. **GitHub Actions automatically**:
   - Builds release artifacts
   - Creates GitHub release
   - Uploads signed binaries
   - Generates release notes

## 📊 Performance

### Benchmarks

Current performance characteristics:

- **Filter application**: <100ms for standard filters on iPhone 15
- **Image processing**: Real-time preview up to 4K images
- **Memory usage**: <50MB peak for typical editing sessions
- **App launch**: <2s cold start on modern devices

### Optimization Features

- **Core Image pipeline**: Hardware-accelerated image processing
- **Memory management**: Automatic cleanup of large image buffers
- **Async processing**: Non-blocking UI during filter application
- **Preview optimization**: Downscaled previews for real-time feedback

## 🧪 Testing

### Test Coverage

- **Unit tests**: Core business logic and image processing
- **Integration tests**: End-to-end filter application workflows
- **UI tests**: Critical user workflows on both platforms
- **Performance tests**: Regression detection for processing speed

### Running Tests

```bash
# All tests with coverage
./Scripts/test.sh --coverage

# Platform-specific tests
./Scripts/test.sh --ios
./Scripts/test.sh --macos

# Performance and UI tests
./Scripts/test.sh --performance --ui
```

## 📱 Platform Features

### iOS App
- **Photo library integration**: Direct import from Photos app
- **Export options**: JPEG, PNG, HEIF with quality control
- **Touch-optimized UI**: Gesture-based controls and navigation
- **iOS-specific features**: Share sheet integration, background processing

### macOS App
- **Drag & drop support**: Direct file import from Finder
- **Menu integration**: Full macOS menu bar with keyboard shortcuts
- **Multi-window support**: Work with multiple images simultaneously
- **Export options**: DMG distribution, Mac App Store ready

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

### Development Setup for Contributors

1. **Fork the repository**
2. **Clone your fork** and run `./Scripts/setup.sh`
3. **Create a feature branch** from `main`
4. **Make your changes** following our coding standards
5. **Test thoroughly** with `./Scripts/test.sh --coverage`
6. **Submit a pull request** with clear description

### Recognition

Contributors are recognized in our [CONTRIBUTORS.md](CONTRIBUTORS.md) file.

## 📄 License

FilterCraft is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## 🔗 Links

- **Documentation**: [filtercraft.dev/docs](https://filtercraft.dev/docs)
- **API Reference**: [filtercraft.dev/api](https://filtercraft.dev/api)
- **Issue Tracker**: [GitHub Issues](https://github.com/filtercraft/filtercraft/issues)
- **Discussions**: [GitHub Discussions](https://github.com/filtercraft/filtercraft/discussions)

## 📈 Status

- **Version**: 1.0.0
- **Status**: Active Development
- **Platform Support**: iOS 16.0+, macOS 12.0+
- **Swift Version**: 5.9+
- **Last Updated**: August 2025

---

<div align="center">
  <strong>Built with ❤️ using SwiftUI and Core Image</strong>
  <br>
  <sub>Professional photo editing for iOS and macOS</sub>
</div>
