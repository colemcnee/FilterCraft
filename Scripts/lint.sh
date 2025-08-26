#!/bin/bash

# FilterCraft Code Quality and Linting Script
# Runs all code quality checks

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

echo "🔍 Running FilterCraft code quality checks..."

# Parse command line arguments
FIX=false
STRICT=false
FORMAT_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX=true
            shift
            ;;
        --strict)
            STRICT=true
            shift
            ;;
        --format-only)
            FORMAT_ONLY=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --fix         Automatically fix issues where possible"
            echo "  --strict      Use strict mode (warnings become errors)"
            echo "  --format-only Run only formatting checks"
            echo "  --help, -h    Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                # Run all quality checks"
            echo "  $0 --fix          # Run checks and fix issues"
            echo "  $0 --strict       # Run with strict validation"
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
ISSUES_FOUND=0
LINT_START_TIME=$(date +%s)

# 1. Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    log_error "SwiftLint is not installed. Please install it with: brew install swiftlint"
    exit 1
fi

# 2. Run SwiftLint
log_info "Running SwiftLint..."

SWIFTLINT_ARGS=""
if [[ "$FIX" == true ]]; then
    SWIFTLINT_ARGS="--fix"
    log_info "Running SwiftLint with auto-fix enabled"
else
    SWIFTLINT_ARGS="--strict"
    if [[ "$STRICT" == true ]]; then
        log_info "Running SwiftLint in strict mode"
    fi
fi

# Run SwiftLint and capture output
SWIFTLINT_OUTPUT=$(swiftlint lint $SWIFTLINT_ARGS --config .swiftlint.yml 2>&1) || SWIFTLINT_EXIT_CODE=$?

if [[ ${SWIFTLINT_EXIT_CODE:-0} -eq 0 ]]; then
    log_success "SwiftLint passed"
else
    log_warning "SwiftLint found issues:"
    echo "$SWIFTLINT_OUTPUT"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# Skip additional checks if format-only mode
if [[ "$FORMAT_ONLY" == true ]]; then
    if [[ $ISSUES_FOUND -eq 0 ]]; then
        log_success "Code formatting looks good! ✨"
        exit 0
    else
        log_error "Code formatting issues found"
        exit 1
    fi
fi

# 3. Check for common Swift issues
log_info "Checking for common Swift issues..."

# Check for TODO/FIXME comments
TODO_COUNT=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -l "TODO\|FIXME\|HACK" {} \; | wc -l)
if [[ $TODO_COUNT -gt 0 ]]; then
    log_warning "Found $TODO_COUNT files with TODO/FIXME/HACK comments"
    if [[ "$STRICT" == true ]]; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# Check for print statements in production code
PRINT_COUNT=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -not -path "./Tests/*" -exec grep -l "print(" {} \; | wc -l)
if [[ $PRINT_COUNT -gt 0 ]]; then
    log_warning "Found $PRINT_COUNT files with print statements (consider using proper logging)"
    if [[ "$STRICT" == true ]]; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# Check for force unwrapping
FORCE_UNWRAP_COUNT=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -c "!" {} \; | awk '{sum+=$1} END {print sum+0}')
if [[ $FORCE_UNWRAP_COUNT -gt 50 ]]; then  # Reasonable threshold
    log_warning "High number of potential force unwraps ($FORCE_UNWRAP_COUNT occurrences)"
    log_info "Consider using optional binding or nil coalescing where appropriate"
fi

# 4. Check file organization
log_info "Checking file organization..."

# Check for large files
LARGE_FILES=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec wc -l {} \; | awk '$1 > 500 {print $2, "(" $1, "lines)"}')
if [[ -n "$LARGE_FILES" ]]; then
    log_warning "Large files found (consider refactoring):"
    echo "$LARGE_FILES"
    if [[ "$STRICT" == true ]]; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# Check for proper import organization
log_info "Checking import statements..."
UNORGANIZED_IMPORTS=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -l "import.*Foundation.*import.*UIKit\|import.*UIKit.*import.*Foundation" {} \; | wc -l)
if [[ $UNORGANIZED_IMPORTS -gt 0 ]]; then
    log_warning "Found $UNORGANIZED_IMPORTS files with potentially unorganized imports"
fi

# 5. Check documentation
log_info "Checking documentation coverage..."

# Check for public APIs without documentation
UNDOCUMENTED_PUBLIC=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -l "public.*func\|public.*var\|public.*let\|public.*class\|public.*struct" {} \; | wc -l)
if [[ $UNDOCUMENTED_PUBLIC -gt 0 ]]; then
    log_info "Found files with public APIs - ensure they are properly documented"
fi

# 6. Security checks
log_info "Running security checks..."

# Check for hardcoded secrets
SECRET_PATTERNS=("password" "secret" "key" "token" "api_key" "apikey")
for pattern in "${SECRET_PATTERNS[@]}"; do
    SECRET_MATCHES=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -i "$pattern" {} \; | wc -l)
    if [[ $SECRET_MATCHES -gt 0 ]]; then
        log_warning "Found potential hardcoded secrets (pattern: $pattern)"
        if [[ "$STRICT" == true ]]; then
            ISSUES_FOUND=$((ISSUES_FOUND + 1))
        fi
    fi
done

# 7. Performance checks
log_info "Running performance checks..."

# Check for potential performance issues
SYNC_MAIN_QUEUE=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec grep -c "DispatchQueue.main.sync" {} \; | awk '{sum+=$1} END {print sum+0}')
if [[ $SYNC_Main_QUEUE -gt 0 ]]; then
    log_warning "Found $SYNC_MAIN_QUEUE synchronous main queue calls (potential deadlock risk)"
    if [[ "$STRICT" == true ]]; then
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# 8. Test coverage analysis (if available)
log_info "Checking test coverage indicators..."

# Count test files vs implementation files
SWIFT_FILES=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -not -path "./Tests/*" | wc -l)
TEST_FILES=$(find . -name "*Test*.swift" -o -name "*Tests*.swift" | wc -l)

if [[ $TEST_FILES -gt 0 ]]; then
    TEST_RATIO=$((TEST_FILES * 100 / SWIFT_FILES))
    log_info "Test file ratio: $TEST_RATIO% ($TEST_FILES test files for $SWIFT_FILES implementation files)"
    
    if [[ $TEST_RATIO -lt 20 ]]; then
        log_warning "Low test coverage ratio - consider adding more tests"
    else
        log_success "Good test file coverage"
    fi
else
    log_warning "No test files found"
fi

# 9. Generate quality report
LINT_END_TIME=$(date +%s)
LINT_DURATION=$((LINT_END_TIME - LINT_START_TIME))

echo ""
echo "📊 Code Quality Report"
echo "====================="
echo "Duration: ${LINT_DURATION}s"
echo "SwiftLint: $([ ${SWIFTLINT_EXIT_CODE:-0} -eq 0 ] && echo "✅ Passed" || echo "⚠️  Issues found")"
echo "TODO/FIXME comments: $TODO_COUNT"
echo "Print statements: $PRINT_COUNT"
echo "Test file ratio: ${TEST_RATIO:-0}%"
echo ""

if [[ $ISSUES_FOUND -eq 0 ]]; then
    log_success "Code quality checks passed! 🎉"
    
    echo "Quality indicators:"
    echo "• SwiftLint compliance ✅"
    echo "• File organization ✅"
    echo "• Security patterns ✅"
    echo "• Performance patterns ✅"
    
    if [[ "$FIX" == true ]]; then
        echo ""
        log_info "Auto-fixable issues have been corrected"
        log_warning "Please review and commit the changes"
    fi
    
    exit 0
else
    if [[ "$STRICT" == true ]]; then
        log_error "Code quality checks failed in strict mode"
        echo ""
        log_info "Issues found: $ISSUES_FOUND"
        log_warning "Fix these issues before proceeding"
        exit 1
    else
        log_warning "Code quality checks completed with warnings"
        echo ""
        log_info "Issues found: $ISSUES_FOUND"
        log_info "Run with --fix to automatically fix issues where possible"
        log_info "Run with --strict to fail on warnings"
        exit 0
    fi
fi