import Foundation

/// Represents a filter that has been applied to an image with specific parameters
public struct AppliedFilter: Identifiable, Equatable, Sendable {
    /// Unique identifier for this applied filter
    public let id: UUID
    
    /// The type of filter that was applied
    public let filterType: FilterType
    
    /// The intensity at which the filter was applied (0.0 - 1.0)
    public let intensity: Float
    
    /// The timestamp when this filter was applied
    public let appliedAt: Date
    
    /// Creates a new applied filter with the specified parameters
    /// - Parameters:
    ///   - filterType: The type of filter to apply
    ///   - intensity: The intensity of the filter (0.0 - 1.0), defaults to filter's default intensity
    ///   - appliedAt: The timestamp when applied, defaults to current time
    ///   - id: Unique identifier, defaults to new UUID
    public init(
        filterType: FilterType,
        intensity: Float? = nil,
        appliedAt: Date = Date(),
        id: UUID = UUID()
    ) {
        self.id = id
        self.filterType = filterType
        self.intensity = intensity ?? filterType.defaultIntensity
        self.appliedAt = appliedAt
    }
    
    /// Returns a new AppliedFilter with the same properties but different intensity
    /// - Parameter intensity: The new intensity value (0.0 - 1.0)
    /// - Returns: A new AppliedFilter instance with updated intensity
    public func withIntensity(_ intensity: Float) -> AppliedFilter {
        let clampedIntensity = max(0.0, min(1.0, intensity))
        return AppliedFilter(
            filterType: filterType,
            intensity: clampedIntensity,
            appliedAt: appliedAt,
            id: id
        )
    }
    
    /// Indicates whether this filter will have a visible effect
    public var isEffective: Bool {
        return filterType != .none && intensity > 0.0
    }
    
    /// A human-readable description of this applied filter
    public var description: String {
        if filterType == .none {
            return "No Filter"
        }
        let intensityPercent = Int(intensity * 100)
        return "\(filterType.displayName) (\(intensityPercent)%)"
    }
}
