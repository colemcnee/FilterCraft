import Foundation

/// Filter category for organizing filters in the UI
public enum FilterCategory: String, CaseIterable {
    case basic = "Basic"
    case artistic = "Artistic"
    case mood = "Mood"
    
    public var displayName: String {
        rawValue
    }
}

/// Represents the different types of photo filters available in FilterCraft
public enum FilterType: String, CaseIterable, Identifiable {
    case none = "none"
    case vintage = "vintage"
    case blackAndWhite = "blackAndWhite"
    case vibrant = "vibrant"
    case sepia = "sepia"
    case cool = "cool"
    case warm = "warm"
    case dramatic = "dramatic"
    case soft = "soft"
    
    public var id: String { rawValue }
    
    /// Human-readable display name for the filter
    public var displayName: String {
        switch self {
        case .none:
            return "None"
        case .vintage:
            return "Vintage"
        case .blackAndWhite:
            return "B&W"
        case .vibrant:
            return "Vibrant"
        case .sepia:
            return "Sepia"
        case .cool:
            return "Cool"
        case .warm:
            return "Warm"
        case .dramatic:
            return "Dramatic"
        case .soft:
            return "Soft"
        }
    }
    
    /// SF Symbol icon name for UI representation
    public var iconName: String {
        switch self {
        case .none:
            return "photo"
        case .vintage:
            return "camera.filters"
        case .blackAndWhite:
            return "circle.lefthalf.filled"
        case .vibrant:
            return "sun.max"
        case .sepia:
            return "leaf"
        case .cool:
            return "snowflake"
        case .warm:
            return "flame"
        case .dramatic:
            return "bolt"
        case .soft:
            return "cloud"
        }
    }
    
    /// Array of Core Image filter names that compose this filter
    public var coreImageFilters: [String] {
        switch self {
        case .none:
            return []
        case .vintage:
            return ["CISepiaTone", "CIVignette", "CIGaussianBlur"]
        case .blackAndWhite:
            return ["CIColorMonochrome"]
        case .vibrant:
            return ["CIVibrance", "CIColorControls"]
        case .sepia:
            return ["CISepiaTone"]
        case .cool:
            return ["CITemperatureAndTint", "CIColorControls"]
        case .warm:
            return ["CITemperatureAndTint", "CIColorControls"]
        case .dramatic:
            return ["CIColorControls", "CIVignette", "CISharpenLuminance"]
        case .soft:
            return ["CIGaussianBlur", "CIColorControls"]
        }
    }
    
    /// Default intensity value for the filter (0.0 - 1.0)
    public var defaultIntensity: Float {
        switch self {
        case .none:
            return 0.0
        case .vintage:
            return 0.7
        case .blackAndWhite:
            return 1.0
        case .vibrant:
            return 0.8
        case .sepia:
            return 0.8
        case .cool:
            return 0.6
        case .warm:
            return 0.6
        case .dramatic:
            return 0.9
        case .soft:
            return 0.4
        }
    }
    
    /// Filter category for organization in UI
    public var category: FilterCategory {
        switch self {
        case .none, .blackAndWhite:
            return .basic
        case .vintage, .sepia:
            return .artistic
        case .vibrant, .cool, .warm, .dramatic, .soft:
            return .mood
        }
    }
    
    /// Filters grouped by category
    public static var filtersByCategory: [FilterCategory: [FilterType]] {
        Dictionary(grouping: FilterType.allCases, by: \.category)
    }
}