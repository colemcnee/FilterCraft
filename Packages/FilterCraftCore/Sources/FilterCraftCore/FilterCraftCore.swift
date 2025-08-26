import Foundation

/// FilterCraftCore - A comprehensive photo filtering framework for iOS and macOS
///
/// FilterCraftCore provides a robust foundation for photo editing applications with:
/// - Comprehensive filter types with Core Image integration
/// - Fine-grained image adjustments (brightness, contrast, saturation, etc.)
/// - Applied filter tracking with intensity control
/// - Clean Swift Package Manager architecture
/// - Multi-platform support (iOS 15+, macOS 12+)
///
/// ## Usage
///
/// ```swift
/// import FilterCraftCore
///
/// // Create filter types
/// let vintageFilter = FilterType.vintage
/// print(vintageFilter.displayName) // "Vintage"
/// print(vintageFilter.coreImageFilters) // ["CISepiaTone", "CIVignette", "CIGaussianBlur"]
///
/// // Apply filters
/// let appliedFilter = AppliedFilter(filterType: .dramatic, intensity: 0.8)
/// print(appliedFilter.description) // "Dramatic (80%)"
///
/// // Adjust images
/// var adjustments = ImageAdjustments()
/// adjustments.brightness = 0.2
/// adjustments.contrast = 0.1
/// print(adjustments.hasAdjustments) // true
/// ```
public struct FilterCraftCore {
    
    /// Current version of FilterCraftCore
    public static let version = "1.0.0"
    
    /// Supported platforms
    public static let supportedPlatforms = ["iOS 15.0+", "macOS 12.0+"]
    
    /// Available filter categories
    public static let availableCategories = FilterCategory.allCases
    
    /// Total number of available filters
    public static let availableFilterCount = FilterType.allCases.count
    
    /// Available adjustment types
    public static let availableAdjustmentTypes = AdjustmentType.allCases
    
    private init() {}
}

/// Convenience extensions for working with filters
public extension FilterCraftCore {
    
    /// Returns all filters organized by category
    static var filtersByCategory: [FilterCategory: [FilterType]] {
        FilterType.filtersByCategory
    }
    
    /// Returns filters for a specific category
    /// - Parameter category: The filter category
    /// - Returns: Array of filter types in that category
    static func filters(for category: FilterCategory) -> [FilterType] {
        FilterType.allCases.filter { $0.category == category }
    }
    
    /// Creates default image adjustments
    /// - Returns: ImageAdjustments with all values at neutral (0.0)
    static func defaultAdjustments() -> ImageAdjustments {
        ImageAdjustments()
    }
    
    /// Creates an applied filter with default intensity
    /// - Parameter filterType: The type of filter to apply
    /// - Returns: AppliedFilter with the filter's default intensity
    static func createAppliedFilter(type: FilterType) -> AppliedFilter {
        AppliedFilter(filterType: type)
    }
}