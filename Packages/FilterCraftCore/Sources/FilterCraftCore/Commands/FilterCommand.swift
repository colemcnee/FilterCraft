import Foundation

/// Command for handling filter application, removal, and intensity changes
///
/// This command efficiently stores filter states and their associated base adjustments
/// without storing image data, making it memory-efficient for undo/redo operations.
public struct FilterCommand: EditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    
    // Store the previous and new filter states
    private let previousFilter: AppliedFilter?
    private let newFilter: AppliedFilter?
    
    // Store the associated base adjustments that filters modify
    private let previousBaseAdjustments: ImageAdjustments
    private let newBaseAdjustments: ImageAdjustments
    
    // Track the type of filter operation
    private let operationType: FilterOperationType
    
    private enum FilterOperationType {
        case apply        // No filter -> Filter
        case remove       // Filter -> No filter
        case change       // Filter A -> Filter B
        case intensity    // Same filter, different intensity
    }
    
    /// Creates a command for applying a new filter
    public init(applyingFilter filter: AppliedFilter, previousBaseAdjustments: ImageAdjustments) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousFilter = nil
        self.newFilter = filter
        self.previousBaseAdjustments = previousBaseAdjustments
        self.newBaseAdjustments = filter.filterType.getScaledAdjustments(intensity: filter.intensity)
        self.operationType = .apply
        self.description = "Apply \(filter.filterType.displayName)"
    }
    
    /// Creates a command for removing the current filter
    public init(removingFilter filter: AppliedFilter, baseAdjustments: ImageAdjustments) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousFilter = filter
        self.newFilter = nil
        self.previousBaseAdjustments = baseAdjustments
        self.newBaseAdjustments = ImageAdjustments() // Reset to neutral
        self.operationType = .remove
        self.description = "Remove \(filter.filterType.displayName)"
    }
    
    /// Creates a command for changing from one filter to another
    public init(
        changingFromFilter previousFilter: AppliedFilter,
        toFilter newFilter: AppliedFilter,
        previousBaseAdjustments: ImageAdjustments
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousFilter = previousFilter
        self.newFilter = newFilter
        self.previousBaseAdjustments = previousBaseAdjustments
        self.newBaseAdjustments = newFilter.filterType.getScaledAdjustments(intensity: newFilter.intensity)
        self.operationType = .change
        self.description = "Change to \(newFilter.filterType.displayName)"
    }
    
    /// Creates a command for changing filter intensity
    public init(
        changingIntensityOf filter: AppliedFilter,
        from previousIntensity: Float,
        to newIntensity: Float,
        previousBaseAdjustments: ImageAdjustments
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousFilter = filter.withIntensity(previousIntensity)
        self.newFilter = filter.withIntensity(newIntensity)
        self.previousBaseAdjustments = previousBaseAdjustments
        self.newBaseAdjustments = filter.filterType.getScaledAdjustments(intensity: newIntensity)
        self.operationType = .intensity
        
        let previousPercent = Int(previousIntensity * 100)
        let newPercent = Int(newIntensity * 100)
        self.description = "Adjust \(filter.filterType.displayName) (\(previousPercent)% → \(newPercent)%)"
    }
    
    public func execute(on session: EditSession) async {
        await session.setAppliedFilterDirectly(newFilter)
        await session.setBaseAdjustmentsDirectly(newBaseAdjustments)
    }
    
    public func undo(on session: EditSession) async {
        await session.setAppliedFilterDirectly(previousFilter)
        await session.setBaseAdjustmentsDirectly(previousBaseAdjustments)
    }
    
    public var estimatedDataSize: Int {
        // AppliedFilter contains UUID (16 bytes), FilterType (small enum), Float (4 bytes), Date (8 bytes)
        // Two AppliedFilter optionals ~= 60 bytes
        // Two ImageAdjustments ~= 64 bytes
        // Enum and other data ~= 20 bytes
        return 144
    }
}

/// Composite command for applying filter presets that modify multiple aspects
public struct FilterPresetCommand: CompositeEditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    public let subCommands: [EditCommand]
    
    /// Creates a preset command that applies a filter and additional adjustments
    public init(
        filter: AppliedFilter,
        additionalAdjustments: [(AdjustmentType, Float)] = [],
        previousFilter: AppliedFilter?,
        previousBaseAdjustments: ImageAdjustments,
        previousUserAdjustments: ImageAdjustments,
        presetName: String
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.description = "Apply \(presetName) Preset"
        
        var commands: [EditCommand] = []
        
        // Filter change command
        if let previousFilter = previousFilter {
            commands.append(FilterCommand(
                changingFromFilter: previousFilter,
                toFilter: filter,
                previousBaseAdjustments: previousBaseAdjustments
            ))
        } else {
            commands.append(FilterCommand(
                applyingFilter: filter,
                previousBaseAdjustments: previousBaseAdjustments
            ))
        }
        
        // Additional adjustment commands if any
        if !additionalAdjustments.isEmpty {
            var newUserAdjustments = previousUserAdjustments
            for (type, value) in additionalAdjustments {
                newUserAdjustments.setValue(value, for: type)
            }
            
            commands.append(AdjustmentCommand(
                previousUserAdjustments: previousUserAdjustments,
                newUserAdjustments: newUserAdjustments,
                description: "Apply preset adjustments"
            ))
        }
        
        self.subCommands = commands
    }
}

/// Smart filter command that can optimize filter transitions
public struct SmartFilterCommand: EditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    
    private let transition: FilterTransition
    
    private struct FilterTransition {
        let previousFilter: AppliedFilter?
        let newFilter: AppliedFilter?
        let previousBaseAdjustments: ImageAdjustments
        let newBaseAdjustments: ImageAdjustments
        let optimizationType: OptimizationType
        
        enum OptimizationType {
            case standard      // Normal filter change
            case intensityOnly // Only intensity changed, same filter
            case similar       // Filters are similar, can optimize
        }
    }
    
    public init(
        from previousFilter: AppliedFilter?,
        to newFilter: AppliedFilter?,
        previousBaseAdjustments: ImageAdjustments
    ) {
        self.id = UUID()
        self.timestamp = Date()
        
        let newBaseAdjustments = newFilter?.filterType.getScaledAdjustments(intensity: newFilter?.intensity ?? 0) ?? ImageAdjustments()
        
        // Determine optimization type
        let optimizationType: FilterTransition.OptimizationType
        if let prev = previousFilter, let new = newFilter {
            if prev.filterType == new.filterType {
                optimizationType = .intensityOnly
                let prevPercent = Int(prev.intensity * 100)
                let newPercent = Int(new.intensity * 100)
                self.description = "Adjust \(new.filterType.displayName) (\(prevPercent)% → \(newPercent)%)"
            } else if prev.filterType.category == new.filterType.category {
                optimizationType = .similar
                self.description = "Change to \(new.filterType.displayName)"
            } else {
                optimizationType = .standard
                self.description = "Change to \(new.filterType.displayName)"
            }
        } else if let new = newFilter {
            optimizationType = .standard
            self.description = "Apply \(new.filterType.displayName)"
        } else if let prev = previousFilter {
            optimizationType = .standard
            self.description = "Remove \(prev.filterType.displayName)"
        } else {
            optimizationType = .standard
            self.description = "No filter change"
        }
        
        self.transition = FilterTransition(
            previousFilter: previousFilter,
            newFilter: newFilter,
            previousBaseAdjustments: previousBaseAdjustments,
            newBaseAdjustments: newBaseAdjustments,
            optimizationType: optimizationType
        )
    }
    
    public func execute(on session: EditSession) async {
        await session.setAppliedFilterDirectly(transition.newFilter)
        await session.setBaseAdjustmentsDirectly(transition.newBaseAdjustments)
    }
    
    public func undo(on session: EditSession) async {
        await session.setAppliedFilterDirectly(transition.previousFilter)
        await session.setBaseAdjustmentsDirectly(transition.previousBaseAdjustments)
    }
    
    public var estimatedDataSize: Int {
        // Similar to FilterCommand but with optimization metadata
        return 160
    }
}
