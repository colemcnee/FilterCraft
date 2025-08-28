import Foundation
import CoreImage

/// Command for handling various reset operations
///
/// Reset commands store complete state snapshots since they need to restore
/// the entire editing state. They include smart memory management to avoid
/// storing unnecessary data.
public struct ResetCommand: EditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    
    // Store complete previous state for reset operations
    private let previousState: EditSessionSnapshot
    private let resetType: ResetType
    
    private enum ResetType {
        case complete          // Reset everything to original image
        case adjustments       // Reset only adjustments, keep filters
        case filters          // Reset only filters, keep adjustments
        case userAdjustments  // Reset only user adjustments, keep base adjustments
    }
    
    /// Represents a snapshot of the edit session state
    private struct EditSessionSnapshot {
        let baseAdjustments: ImageAdjustments
        let userAdjustments: ImageAdjustments
        let appliedFilter: AppliedFilter?
        let hasEdits: Bool
        
        @MainActor
        init(from session: EditSession) {
            self.baseAdjustments = session.baseAdjustments
            self.userAdjustments = session.userAdjustments
            self.appliedFilter = session.appliedFilter
            self.hasEdits = session.hasEdits
        }
    }
    
    /// Creates a command for complete reset to original image
    @MainActor
    public init(completeResetFrom session: EditSession) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousState = EditSessionSnapshot(from: session)
        self.resetType = .complete
        self.description = "Reset to Original"
    }
    
    /// Creates a command for resetting only adjustments
    @MainActor
    public init(adjustmentResetFrom session: EditSession) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousState = EditSessionSnapshot(from: session)
        self.resetType = .adjustments
        self.description = "Reset Adjustments"
    }
    
    /// Creates a command for resetting only filters
    @MainActor
    public init(filterResetFrom session: EditSession) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousState = EditSessionSnapshot(from: session)
        self.resetType = .filters
        self.description = "Reset Filter"
    }
    
    /// Creates a command for resetting only user adjustments (keeping base adjustments from filters)
    @MainActor
    public init(userAdjustmentResetFrom session: EditSession) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousState = EditSessionSnapshot(from: session)
        self.resetType = .userAdjustments
        self.description = "Reset Manual Adjustments"
    }
    
    public func execute(on session: EditSession) async {
        switch resetType {
        case .complete:
            await session.setBaseAdjustmentsDirectly(ImageAdjustments())
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            await session.setAppliedFilterDirectly(nil)
            
        case .adjustments:
            await session.setBaseAdjustmentsDirectly(ImageAdjustments())
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            // Keep the filter but reset its base adjustments
            let currentFilter = await session.appliedFilter
            if let filter = currentFilter {
                await session.setAppliedFilterDirectly(filter)
                await session.setBaseAdjustmentsDirectly(ImageAdjustments())
            }
            
        case .filters:
            await session.setAppliedFilterDirectly(nil)
            await session.setBaseAdjustmentsDirectly(ImageAdjustments())
            // Keep user adjustments
            
        case .userAdjustments:
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            // Keep base adjustments and filter
        }
    }
    
    public func undo(on session: EditSession) async {
        // Restore the complete previous state
        await session.setBaseAdjustmentsDirectly(previousState.baseAdjustments)
        await session.setUserAdjustmentsDirectly(previousState.userAdjustments)
        await session.setAppliedFilterDirectly(previousState.appliedFilter)
    }
    
    public var estimatedDataSize: Int {
        // EditSessionSnapshot contains:
        // - Two ImageAdjustments (64 bytes each) = 128 bytes
        // - Optional AppliedFilter (~30 bytes)
        // - Bool (1 byte)
        // - Enum overhead (~10 bytes)
        return 169
    }
}

/// Specialized reset command for smart reset operations
public struct SmartResetCommand: EditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    
    private let resetStrategy: ResetStrategy
    private let previousState: EditSessionSnapshot
    
    private struct EditSessionSnapshot {
        let baseAdjustments: ImageAdjustments
        let userAdjustments: ImageAdjustments
        let appliedFilter: AppliedFilter?
        
        @MainActor
        init(from session: EditSession) {
            self.baseAdjustments = session.baseAdjustments
            self.userAdjustments = session.userAdjustments
            self.appliedFilter = session.appliedFilter
        }
    }
    
    private enum ResetStrategy {
        case minimal      // Reset only the most recent changes
        case significant  // Reset significant changes, keep minor tweaks
        case complete     // Reset everything
    }
    
    /// Creates a smart reset command that analyzes the current state and resets intelligently
    @MainActor
    public init(smartResetFrom session: EditSession) {
        self.id = UUID()
        self.timestamp = Date()
        self.previousState = EditSessionSnapshot(from: session)
        
        // Analyze the current state to determine the best reset strategy
        let hasSignificantUserAdjustments = session.userAdjustments.hasAdjustments &&
                                          (abs(session.userAdjustments.brightness) > 0.2 ||
                                           abs(session.userAdjustments.contrast) > 0.2 ||
                                           abs(session.userAdjustments.saturation) > 0.3)
        
        let hasFilter = session.appliedFilter?.isEffective == true
        
        if hasFilter && hasSignificantUserAdjustments {
            self.resetStrategy = .complete
            self.description = "Smart Reset (Complete)"
        } else if hasSignificantUserAdjustments {
            self.resetStrategy = .significant
            self.description = "Smart Reset (Adjustments)"
        } else {
            self.resetStrategy = .minimal
            self.description = "Smart Reset (Recent Changes)"
        }
    }
    
    public func execute(on session: EditSession) async {
        switch resetStrategy {
        case .minimal:
            // Reset only user adjustments, keep everything else
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            
        case .significant:
            // Reset user adjustments and reduce filter intensity if present
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            let currentFilter = await session.appliedFilter
            if let filter = currentFilter, filter.intensity > 0.5 {
                let reducedFilter = filter.withIntensity(0.3)
                await session.setAppliedFilterDirectly(reducedFilter)
                let newBaseAdjustments = filter.filterType.getScaledAdjustments(intensity: 0.3)
                await session.setBaseAdjustmentsDirectly(newBaseAdjustments)
            }
            
        case .complete:
            // Complete reset
            await session.setBaseAdjustmentsDirectly(ImageAdjustments())
            await session.setUserAdjustmentsDirectly(ImageAdjustments())
            await session.setAppliedFilterDirectly(nil)
        }
    }
    
    public func undo(on session: EditSession) async {
        // Always restore the complete previous state regardless of strategy
        await session.setBaseAdjustmentsDirectly(previousState.baseAdjustments)
        await session.setUserAdjustmentsDirectly(previousState.userAdjustments)
        await session.setAppliedFilterDirectly(previousState.appliedFilter)
    }
    
    public var estimatedDataSize: Int {
        // Similar to ResetCommand
        return 180
    }
}

/// Batch reset command for complex reset operations
public struct BatchResetCommand: CompositeEditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    public let subCommands: [EditCommand]
    
    /// Creates a batch reset command for step-by-step reset
    @MainActor
    public init(stepwiseResetFrom session: EditSession, steps: [String] = []) {
        self.id = UUID()
        self.timestamp = Date()
        self.description = "Stepwise Reset"
        
        var commands: [EditCommand] = []
        
        // Create individual reset commands for each aspect
        if session.userAdjustments.hasAdjustments {
            commands.append(ResetCommand(userAdjustmentResetFrom: session))
        }
        
        if session.appliedFilter?.isEffective == true {
            commands.append(ResetCommand(filterResetFrom: session))
        }
        
        if session.baseAdjustments.hasAdjustments {
            commands.append(ResetCommand(adjustmentResetFrom: session))
        }
        
        // If no specific resets needed, do complete reset
        if commands.isEmpty {
            commands.append(ResetCommand(completeResetFrom: session))
        }
        
        self.subCommands = commands
    }
}