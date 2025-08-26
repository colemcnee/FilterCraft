#!/bin/bash

# FilterCraft Build Script
# Builds all targets in the project

set -e  # Exit on any error

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

echo "🔨 Building FilterCraft..."

# Parse command line arguments
PLATFORM=""
CONFIGURATION="Debug"
CLEAN=false
ARCHIVE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --ios)
            PLATFORM="ios"
            shift
            ;;
        --macos)
            PLATFORM="macos"
            shift
            ;;
        --release)
            CONFIGURATION="Release"
            shift
            ;;
        --debug)
            CONFIGURATION="Debug"
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --archive)
            ARCHIVE=true
            CONFIGURATION="Release"  # Force release for archives
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ios         Build iOS target only"
            echo "  --macos       Build macOS target only"
            echo "  --release     Build in Release configuration"
            echo "  --debug       Build in Debug configuration (default)"
            echo "  --clean       Clean before building"
            echo "  --archive     Create archive (implies --release)"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Build all targets in Debug"
            echo "  $0 --ios --release    # Build iOS target in Release"
            echo "  $0 --clean --archive  # Clean, then create archives"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Initialize results tracking
FAILED_BUILDS=()
BUILD_START_TIME=$(date +%s)

# Clean if requested
if [[ "$CLEAN" == true ]]; then
    log_info "Cleaning build directories..."
    
    # Clean Xcode derived data
    if [[ -d "~/Library/Developer/Xcode/DerivedData" ]]; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/FilterCraft-*
    fi
    
    # Clean build directories
    rm -rf build/
    
    # Clean Swift package builds
    cd Packages/FilterCraftCore
    swift package clean
    cd ../..
    
    log_success "Clean completed"
fi

# Create build output directory
mkdir -p build/{ios,macos,logs}

# 1. Build Swift Package
log_info "Building FilterCraftCore package..."
cd Packages/FilterCraftCore

if swift build; then
    log_success "FilterCraftCore package built successfully"
else
    log_error "FilterCraftCore package build failed"
    FAILED_BUILDS+=("FilterCraftCore")
fi

cd ../..

# 2. Build iOS App
if [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "ios" ]]; then
    log_info "Building iOS app ($CONFIGURATION configuration)..."
    
    IOS_DESTINATION="generic/platform=iOS"
    if [[ "$CONFIGURATION" == "Debug" ]]; then
        IOS_DESTINATION="platform=iOS Simulator,name=iPhone 15"
    fi
    
    BUILD_ARGS="-scheme FilterCraft-iOS -destination \"$IOS_DESTINATION\" -configuration $CONFIGURATION"
    
    # Add code signing parameters for iOS
    if [[ "$CONFIGURATION" == "Debug" ]]; then
        BUILD_ARGS="$BUILD_ARGS CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO"
    fi
    
    if [[ "$ARCHIVE" == true ]]; then
        log_info "Creating iOS archive..."
        if xcodebuild archive $BUILD_ARGS -archivePath "build/ios/FilterCraft-iOS.xcarchive"; then
            log_success "iOS archive created successfully"
            
            # Export IPA
            log_info "Exporting iOS IPA..."
            cat > build/ios/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>signingStyle</key>
    <string>manual</string>
</dict>
</plist>
EOF
            
            if xcodebuild -exportArchive \
                -archivePath "build/ios/FilterCraft-iOS.xcarchive" \
                -exportPath "build/ios" \
                -exportOptionsPlist "build/ios/ExportOptions.plist"; then
                log_success "iOS IPA exported successfully"
            else
                log_warning "iOS IPA export failed (may require proper signing)"
            fi
        else
            log_error "iOS archive creation failed"
            FAILED_BUILDS+=("iOS-Archive")
        fi
    else
        if xcodebuild build $BUILD_ARGS; then
            log_success "iOS app built successfully"
        else
            log_error "iOS app build failed"
            FAILED_BUILDS+=("iOS")
        fi
    fi
fi

# 3. Build macOS App
if [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "macos" ]]; then
    log_info "Building macOS app ($CONFIGURATION configuration)..."
    
    BUILD_ARGS="-scheme FilterCraft-macOS -destination \"platform=macOS\" -configuration $CONFIGURATION"
    
    if [[ "$ARCHIVE" == true ]]; then
        log_info "Creating macOS archive..."
        if xcodebuild archive $BUILD_ARGS -archivePath "build/macos/FilterCraft-macOS.xcarchive"; then
            log_success "macOS archive created successfully"
            
            # Export app
            log_info "Exporting macOS app..."
            cat > build/macos/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF
            
            if xcodebuild -exportArchive \
                -archivePath "build/macos/FilterCraft-macOS.xcarchive" \
                -exportPath "build/macos" \
                -exportOptionsPlist "build/macos/ExportOptions.plist"; then
                log_success "macOS app exported successfully"
                
                # Create DMG if app was exported successfully
                if [[ -f "build/macos/FilterCraft.app" ]]; then
                    log_info "Creating DMG..."
                    hdiutil create -volname "FilterCraft" -srcfolder "build/macos/FilterCraft.app" -ov -format UDZO "build/macos/FilterCraft.dmg"
                    log_success "DMG created: build/macos/FilterCraft.dmg"
                fi
            else
                log_warning "macOS app export failed (may require proper signing)"
            fi
        else
            log_error "macOS archive creation failed"
            FAILED_BUILDS+=("macOS-Archive")
        fi
    else
        if xcodebuild build $BUILD_ARGS; then
            log_success "macOS app built successfully"
        else
            log_error "macOS app build failed"
            FAILED_BUILDS+=("macOS")
        fi
    fi
fi

# 4. Build Summary
BUILD_END_TIME=$(date +%s)
BUILD_DURATION=$((BUILD_END_TIME - BUILD_START_TIME))

echo ""
echo "📊 Build Summary"
echo "================"
echo "Configuration: $CONFIGURATION"
echo "Duration: ${BUILD_DURATION}s"
echo ""

if [[ ${#FAILED_BUILDS[@]} -eq 0 ]]; then
    log_success "All builds completed successfully! 🎉"
    
    echo "Built targets:"
    echo "• FilterCraftCore package ✅"
    [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "ios" ]] && echo "• iOS app ✅"
    [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "macos" ]] && echo "• macOS app ✅"
    
    if [[ "$ARCHIVE" == true ]]; then
        echo ""
        echo "Archives created in build/ directory:"
        [[ -f "build/ios/FilterCraft-iOS.xcarchive" ]] && echo "• iOS: build/ios/FilterCraft-iOS.xcarchive"
        [[ -f "build/macos/FilterCraft-macOS.xcarchive" ]] && echo "• macOS: build/macos/FilterCraft-macOS.xcarchive"
        
        echo ""
        echo "Exported apps:"
        [[ -f "build/ios/FilterCraft.ipa" ]] && echo "• iOS: build/ios/FilterCraft.ipa"
        [[ -f "build/macos/FilterCraft.app" ]] && echo "• macOS: build/macos/FilterCraft.app"
        [[ -f "build/macos/FilterCraft.dmg" ]] && echo "• macOS DMG: build/macos/FilterCraft.dmg"
    fi
    
    echo ""
    log_info "Next steps:"
    echo "• Run tests: ./Scripts/test.sh"
    echo "• Check code quality: ./Scripts/lint.sh"
    echo "• Open in Xcode: open FilterCraft.xcworkspace"
    
    exit 0
else
    log_error "Some builds failed:"
    for build in "${FAILED_BUILDS[@]}"; do
        echo "  ❌ $build"
    done
    
    echo ""
    log_warning "Check the output above for detailed error information"
    log_info "You can build specific platforms using --ios or --macos flags"
    
    exit 1
fi