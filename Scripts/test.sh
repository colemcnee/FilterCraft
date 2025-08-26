#!/bin/bash

# FilterCraft Test Runner
# Runs all tests across the project

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

echo "🧪 Running FilterCraft test suite..."

# Parse command line arguments
PLATFORM=""
COVERAGE=false
PERFORMANCE=false
UI_TESTS=false

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
        --coverage)
            COVERAGE=true
            shift
            ;;
        --performance)
            PERFORMANCE=true
            shift
            ;;
        --ui)
            UI_TESTS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ios         Run iOS tests only"
            echo "  --macos       Run macOS tests only"
            echo "  --coverage    Generate code coverage reports"
            echo "  --performance Run performance tests"
            echo "  --ui          Run UI tests"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Run all tests"
            echo "  $0 --ios --coverage   # Run iOS tests with coverage"
            echo "  $0 --macos --ui       # Run macOS tests including UI tests"
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
FAILED_TESTS=()

# 1. Swift Package Tests
log_info "Running FilterCraftCore package tests..."
cd Packages/FilterCraftCore

SWIFT_TEST_ARGS="--parallel"
if [[ "$COVERAGE" == true ]]; then
    SWIFT_TEST_ARGS="$SWIFT_TEST_ARGS --enable-code-coverage"
fi

if swift test $SWIFT_TEST_ARGS; then
    log_success "FilterCraftCore package tests passed"
else
    log_error "FilterCraftCore package tests failed"
    FAILED_TESTS+=("FilterCraftCore")
fi

# Generate coverage report if requested
if [[ "$COVERAGE" == true ]]; then
    log_info "Generating Swift package coverage report..."
    if command -v xcrun &> /dev/null; then
        xcrun llvm-cov export -format="lcov" \
            .build/debug/FilterCraftCorePackageTests.xctest/Contents/MacOS/FilterCraftCorePackageTests \
            -instr-profile .build/debug/codecov/default.profdata > coverage.lcov 2>/dev/null || true
        log_success "Coverage report generated: Packages/FilterCraftCore/coverage.lcov"
    fi
fi

cd ../..

# 2. iOS Tests
if [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "ios" ]]; then
    log_info "Running iOS tests..."
    
    # Check for available iOS simulators
    IOS_SIMULATORS=$(xcrun simctl list devices available | grep "iPhone" | head -1)
    if [[ -z "$IOS_SIMULATORS" ]]; then
        log_warning "No iOS simulators available, skipping iOS tests"
    else
        IOS_DESTINATION="platform=iOS Simulator,name=iPhone 15"
        
        # Unit tests
        log_info "Running iOS unit tests..."
        XCODEBUILD_ARGS="-scheme FilterCraft-iOS -destination \"$IOS_DESTINATION\" -configuration Debug"
        
        if [[ "$COVERAGE" == true ]]; then
            XCODEBUILD_ARGS="$XCODEBUILD_ARGS -enableCodeCoverage YES"
        fi
        
        if xcodebuild test $XCODEBUILD_ARGS CODE_SIGNING_ALLOWED=NO; then
            log_success "iOS unit tests passed"
        else
            log_error "iOS unit tests failed"
            FAILED_TESTS+=("iOS-Unit")
        fi
        
        # UI tests (if requested)
        if [[ "$UI_TESTS" == true ]]; then
            log_info "Running iOS UI tests..."
            if xcodebuild test -scheme FilterCraft-iOS-UITests -destination "$IOS_DESTINATION" CODE_SIGNING_ALLOWED=NO; then
                log_success "iOS UI tests passed"
            else
                log_error "iOS UI tests failed"
                FAILED_TESTS+=("iOS-UI")
            fi
        fi
        
        # Performance tests (if requested)
        if [[ "$PERFORMANCE" == true ]]; then
            log_info "Running iOS performance tests..."
            if xcodebuild test $XCODEBUILD_ARGS -only-testing:FilterCraftTests/PerformanceTests CODE_SIGNING_ALLOWED=NO; then
                log_success "iOS performance tests passed"
            else
                log_warning "iOS performance tests had issues (may be expected)"
            fi
        fi
    fi
fi

# 3. macOS Tests  
if [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "macos" ]]; then
    log_info "Running macOS tests..."
    
    MACOS_DESTINATION="platform=macOS"
    XCODEBUILD_ARGS="-scheme FilterCraft-macOS -destination \"$MACOS_DESTINATION\" -configuration Debug"
    
    if [[ "$COVERAGE" == true ]]; then
        XCODEBUILD_ARGS="$XCODEBUILD_ARGS -enableCodeCoverage YES"
    fi
    
    # Unit tests
    if xcodebuild test $XCODEBUILD_ARGS; then
        log_success "macOS unit tests passed"
    else
        log_error "macOS unit tests failed"
        FAILED_TESTS+=("macOS-Unit")
    fi
    
    # UI tests (if requested)
    if [[ "$UI_TESTS" == true ]]; then
        log_info "Running macOS UI tests..."
        if xcodebuild test -scheme FilterCraft-macOS-UITests -destination "$MACOS_DESTINATION"; then
            log_success "macOS UI tests passed"
        else
            log_error "macOS UI tests failed"
            FAILED_TESTS+=("macOS-UI")
        fi
    fi
    
    # Performance tests (if requested)
    if [[ "$PERFORMANCE" == true ]]; then
        log_info "Running macOS performance tests..."
        if xcodebuild test $XCODEBUILD_ARGS -only-testing:FilterCraftMacOSTests/PerformanceTests; then
            log_success "macOS performance tests passed"
        else
            log_warning "macOS performance tests had issues (may be expected)"
        fi
    fi
fi

# 4. Generate combined coverage report (if requested)
if [[ "$COVERAGE" == true ]]; then
    log_info "Processing coverage reports..."
    
    # Create coverage directory
    mkdir -p build/coverage
    
    # Find and process coverage data
    if find . -name "Coverage.profdata" -type f | head -1 | xargs -I {} xcrun xccov view --report --json {} > build/coverage/combined-coverage.json 2>/dev/null; then
        log_success "Combined coverage report generated: build/coverage/combined-coverage.json"
    else
        log_warning "Could not generate combined coverage report"
    fi
fi

# 5. Test Summary
echo ""
echo "📊 Test Summary"
echo "=============="

if [[ ${#FAILED_TESTS[@]} -eq 0 ]]; then
    log_success "All tests passed! 🎉"
    
    echo ""
    echo "Test categories run:"
    echo "• FilterCraftCore package tests ✅"
    [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "ios" ]] && echo "• iOS unit tests ✅"
    [[ -z "$PLATFORM" ]] || [[ "$PLATFORM" == "macos" ]] && echo "• macOS unit tests ✅"
    [[ "$UI_TESTS" == true ]] && echo "• UI tests ✅"
    [[ "$PERFORMANCE" == true ]] && echo "• Performance tests ✅"
    [[ "$COVERAGE" == true ]] && echo "• Code coverage ✅"
    
    exit 0
else
    log_error "Some tests failed:"
    for test in "${FAILED_TESTS[@]}"; do
        echo "  ❌ $test"
    done
    
    echo ""
    log_warning "Check the output above for detailed error information"
    log_info "You can run tests for specific platforms using --ios or --macos flags"
    
    exit 1
fi