#!/bin/bash

# FilterCraft Development Environment Setup Script
# One-command setup for new contributors

set -e  # Exit on any error

echo "🚀 Setting up FilterCraft development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]] || [[ ! -d "Apps" ]] || [[ ! -d "Packages" ]]; then
    log_error "Please run this script from the FilterCraft project root directory"
    exit 1
fi

log_info "Starting FilterCraft development environment setup..."

# 1. Check system requirements
log_info "Checking system requirements..."

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
log_info "macOS version: $MACOS_VERSION"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    log_error "Xcode is not installed. Please install Xcode from the Mac App Store."
    exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -1)
log_success "Found $XCODE_VERSION"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    log_warning "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    log_success "Homebrew is installed"
fi

# 2. Install development tools
log_info "Installing development tools..."

# SwiftLint
if ! command -v swiftlint &> /dev/null; then
    log_info "Installing SwiftLint..."
    brew install swiftlint
else
    log_success "SwiftLint is already installed"
fi

# Fastlane
if ! command -v fastlane &> /dev/null; then
    log_info "Installing Fastlane..."
    brew install fastlane
else
    log_success "Fastlane is already installed"
fi

# Git hooks (pre-commit)
if ! command -v pre-commit &> /dev/null; then
    log_info "Installing pre-commit..."
    brew install pre-commit
else
    log_success "Pre-commit is already installed"
fi

# 3. Setup Swift Package Manager
log_info "Setting up Swift Package Manager..."

cd Packages/FilterCraftCore
if [[ -f "Package.swift" ]]; then
    log_info "Resolving Swift package dependencies..."
    swift package resolve
    log_success "Swift package dependencies resolved"
else
    log_error "Package.swift not found in FilterCraftCore"
    exit 1
fi
cd ../..

# 4. Generate Xcode projects
log_info "Generating Xcode projects with XcodeGen..."

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    log_info "Installing XcodeGen..."
    brew install xcodegen
fi

# Generate iOS project
if [[ -f "Apps/FilterCraft-iOS/project.yml" ]]; then
    log_info "Generating iOS Xcode project..."
    cd Apps/FilterCraft-iOS
    xcodegen generate
    cd ../..
    log_success "iOS project generated"
fi

# Generate macOS project
if [[ -f "Apps/FilterCraft-macOS/project.yml" ]]; then
    log_info "Generating macOS Xcode project..."
    cd Apps/FilterCraft-macOS
    xcodegen generate
    cd ../..
    log_success "macOS project generated"
fi

# 5. Setup Git hooks
log_info "Setting up Git hooks..."

if [[ -f ".pre-commit-config.yaml" ]]; then
    pre-commit install
    log_success "Pre-commit hooks installed"
else
    log_warning "No pre-commit configuration found, skipping Git hooks setup"
fi

# 6. Run initial tests
log_info "Running initial tests to verify setup..."

# Test Swift package
cd Packages/FilterCraftCore
if swift test --parallel; then
    log_success "FilterCraftCore tests passed"
else
    log_warning "Some FilterCraftCore tests failed - this might be expected for a new setup"
fi
cd ../..

# Test iOS build
log_info "Testing iOS build..."
if xcodebuild build -scheme FilterCraft-iOS -destination "platform=iOS Simulator,name=iPhone 15" -quiet CODE_SIGNING_ALLOWED=NO; then
    log_success "iOS build successful"
else
    log_warning "iOS build failed - check your setup"
fi

# Test macOS build
log_info "Testing macOS build..."
if xcodebuild build -scheme FilterCraft-macOS -destination "platform=macOS" -quiet; then
    log_success "macOS build successful"
else
    log_warning "macOS build failed - check your setup"
fi

# 7. Setup complete
echo ""
log_success "🎉 FilterCraft development environment setup complete!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Open FilterCraft.xcworkspace in Xcode"
echo "2. Select your target (iOS or macOS)"
echo "3. Build and run the app"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo "• Run tests: ./Scripts/test.sh"
echo "• Build all targets: ./Scripts/build.sh" 
echo "• Run linting: ./Scripts/lint.sh"
echo "• Fastlane iOS build: fastlane ios build"
echo "• Fastlane macOS build: fastlane mac build"
echo ""
echo -e "${BLUE}Development workflow:${NC}"
echo "1. Create a feature branch: git checkout -b feature/your-feature"
echo "2. Make your changes"
echo "3. Run tests and lint: ./Scripts/test.sh && ./Scripts/lint.sh"
echo "4. Commit your changes (pre-commit hooks will run)"
echo "5. Push and create a pull request"
echo ""
log_success "Happy coding! 🚀"