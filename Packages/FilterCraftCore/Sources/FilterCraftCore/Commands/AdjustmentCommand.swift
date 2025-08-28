import Foundation

/// Command for handling image adjustment changes
///
/// This command stores only the differences between the previous and new adjustments
/// to minimize memory usage. It supports both user adjustments and base adjustments.
public struct AdjustmentCommand: EditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    
    // Store the previous and new adjustment states
    private let previousUserAdjustments: ImageAdjustments
    private let newUserAdjustments: ImageAdjustments
    private let previousBaseAdjustments: ImageAdjustments
    private let newBaseAdjustments: ImageAdjustments
    
    // Track which type of adjustments were changed
    private let adjustmentType: AdjustmentChangeType
    
    private enum AdjustmentChangeType {
        case userOnly
        case baseOnly
        case both
    }
    
    /// Creates a command for user adjustment changes only
    public init(
        previousUserAdjustments: ImageAdjustments,
        newUserAdjustments: ImageAdjustments,
        description: String? = nil
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousUserAdjustments = previousUserAdjustments
        self.newUserAdjustments = newUserAdjustments
        self.previousBaseAdjustments = ImageAdjustments()
        self.newBaseAdjustments = ImageAdjustments()
        self.adjustmentType = .userOnly
        self.description = description ?? Self.generateDescription(
            from: previousUserAdjustments,
            to: newUserAdjustments
        )
    }
    
    /// Creates a command for base adjustment changes only (usually from filter changes)
    public init(
        previousBaseAdjustments: ImageAdjustments,
        newBaseAdjustments: ImageAdjustments,
        description: String
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousUserAdjustments = ImageAdjustments()
        self.newUserAdjustments = ImageAdjustments()
        self.previousBaseAdjustments = previousBaseAdjustments
        self.newBaseAdjustments = newBaseAdjustments
        self.adjustmentType = .baseOnly
        self.description = description
    }
    
    /// Creates a command for both user and base adjustment changes
    public init(
        previousUserAdjustments: ImageAdjustments,
        newUserAdjustments: ImageAdjustments,
        previousBaseAdjustments: ImageAdjustments,
        newBaseAdjustments: ImageAdjustments,
        description: String
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousUserAdjustments = previousUserAdjustments
        self.newUserAdjustments = newUserAdjustments
        self.previousBaseAdjustments = previousBaseAdjustments
        self.newBaseAdjustments = newBaseAdjustments
        self.adjustmentType = .both
        self.description = description
    }
    
    public func execute(on session: EditSession) async {
        switch adjustmentType {
        case .userOnly:
            await session.setUserAdjustmentsDirectly(newUserAdjustments)
        case .baseOnly:
            await session.setBaseAdjustmentsDirectly(newBaseAdjustments)
        case .both:
            await session.setUserAdjustmentsDirectly(newUserAdjustments)
            await session.setBaseAdjustmentsDirectly(newBaseAdjustments)
        }
    }
    
    public func undo(on session: EditSession) async {
        switch adjustmentType {
        case .userOnly:
            await session.setUserAdjustmentsDirectly(previousUserAdjustments)
        case .baseOnly:
            await session.setBaseAdjustmentsDirectly(previousBaseAdjustments)
        case .both:
            await session.setUserAdjustmentsDirectly(previousUserAdjustments)
            await session.setBaseAdjustmentsDirectly(previousBaseAdjustments)
        }
    }
    
    public var estimatedDataSize: Int {
        // Each ImageAdjustments struct has 8 Float values (4 bytes each) = 32 bytes
        // We store 4 ImageAdjustments instances = 128 bytes total
        // Plus enum overhead = ~140 bytes
        return 140
    }
    
    /// Generates a human-readable description of the adjustment changes
    private static func generateDescription(
        from previousAdjustments: ImageAdjustments,
        to newAdjustments: ImageAdjustments
    ) -> String {
        var changes: [String] = []
        
        // Check each adjustment type for changes
        for adjustmentType in AdjustmentType.allCases {
            let previousValue = previousAdjustments.value(for: adjustmentType)
            let newValue = newAdjustments.value(for: adjustmentType)
            
            if abs(previousValue - newValue) > 0.001 { // Account for floating point precision
                let direction = newValue > previousValue ? "increased" : "decreased"
                changes.append("\(adjustmentType.displayName) \(direction)")
            }
        }
        
        if changes.isEmpty {
            return "No adjustment changes"
        } else if changes.count == 1 {
            return "Adjust \(changes[0].capitalized)"
        } else if changes.count <= 3 {
            return "Adjust \(changes.joined(separator: ", "))"
        } else {
            return "Adjust multiple settings (\(changes.count) changes)"
        }
    }
}

/// Batch command for multiple simultaneous adjustment changes
public struct BatchAdjustmentCommand: CompositeEditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    public let subCommands: [EditCommand]
    
    /// Creates a batch command from multiple adjustment commands
    public init(commands: [AdjustmentCommand], description: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.subCommands = commands
        
        if let description = description {
            self.description = description
        } else if commands.count == 1 {
            self.description = commands[0].description
        } else {
            self.description = "Batch adjustment (\(commands.count) changes)"
        }
    }
    
    /// Creates a batch command for multiple related adjustments (e.g., preset application)
    public init(
        adjustmentChanges: [(AdjustmentType, Float)],
        previousAdjustments: ImageAdjustments,
        description: String
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.description = description
        
        var newAdjustments = previousAdjustments
        for (type, value) in adjustmentChanges {
            newAdjustments.setValue(value, for: type)
        }
        
        self.subCommands = [AdjustmentCommand(
            previousUserAdjustments: previousAdjustments,
            newUserAdjustments: newAdjustments,
            description: description
        )]
    }
}