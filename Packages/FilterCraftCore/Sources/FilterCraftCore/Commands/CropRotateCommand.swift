import Foundation

/// Command for crop and rotate operations with undo/redo support
public struct CropRotateCommand: EditCommand {
    public let id = UUID()
    public let timestamp = Date()
    
    private let previousState: CropRotateState
    private let newState: CropRotateState
    
    // MARK: - Initialization
    
    /// Creates a command to change from one crop/rotate state to another
    public init(previousState: CropRotateState, newState: CropRotateState) {
        self.previousState = previousState
        self.newState = newState
    }
    
    /// Creates a command to apply a new crop/rotate state from identity
    public init(applyingState newState: CropRotateState) {
        self.previousState = .identity
        self.newState = newState
    }
    
    /// Creates a command to reset crop/rotate to identity
    public init(resettingFromState previousState: CropRotateState) {
        self.previousState = previousState
        self.newState = .identity
    }
    
    // MARK: - EditCommand Implementation
    
    public var description: String {
        if newState == .identity {
            return "Reset Crop & Rotate"
        }
        
        if previousState == .identity {
            return "Apply \(newState.transformationDescription)"
        }
        
        var changes: [String] = []
        
        // Detect specific changes between states
        if newState.cropRect != previousState.cropRect {
            if previousState.cropRect == CGRect(x: 0, y: 0, width: 1, height: 1) {
                changes.append("Crop")
            } else {
                changes.append("Adjust Crop")
            }
        }
        
        if newState.rotationAngle != previousState.rotationAngle {
            let degrees = Int(newState.rotationDegrees - previousState.rotationDegrees)
            if degrees > 0 {
                changes.append("Rotate +\(degrees)°")
            } else if degrees < 0 {
                changes.append("Rotate \(degrees)°")
            }
        }
        
        if newState.isFlippedHorizontally != previousState.isFlippedHorizontally {
            changes.append(newState.isFlippedHorizontally ? "Flip Horizontal" : "Unflip Horizontal")
        }
        
        if newState.isFlippedVertically != previousState.isFlippedVertically {
            changes.append(newState.isFlippedVertically ? "Flip Vertical" : "Unflip Vertical")
        }
        
        if newState.aspectRatio != previousState.aspectRatio {
            if let aspectRatio = newState.aspectRatio {
                changes.append("Set Aspect Ratio: \(aspectRatio.displayName)")
            } else {
                changes.append("Remove Aspect Ratio")
            }
        }
        
        return changes.isEmpty ? "Crop & Rotate Change" : changes.joined(separator: ", ")
    }
    
    public var memoryFootprint: Int {
        return MemoryLayout<CropRotateState>.size * 2 + 
               MemoryLayout<UUID>.size + 
               MemoryLayout<Date>.size
    }
    
    public func execute(on session: EditSession) async {
        await session.applyCropRotateStateDirectly(newState)
    }
    
    public func undo(on session: EditSession) async {
        await session.applyCropRotateStateDirectly(previousState)
    }
}

// MARK: - Specialized Command Types

public extension CropRotateCommand {
    
    /// Creates a command for crop rectangle changes only
    static func cropChange(from previousRect: CGRect, to newRect: CGRect, aspectRatio: AspectRatio? = nil) -> CropRotateCommand {
        let previousState = CropRotateState(cropRect: previousRect, aspectRatio: aspectRatio)
        let newState = CropRotateState(cropRect: newRect, aspectRatio: aspectRatio)
        return CropRotateCommand(previousState: previousState, newState: newState)
    }
    
    /// Creates a command for rotation changes only
    static func rotationChange(from previousAngle: Float, to newAngle: Float, preservingState currentState: CropRotateState) -> CropRotateCommand {
        let previousState = currentState.withRotation(previousAngle)
        let newState = currentState.withRotation(newAngle)
        return CropRotateCommand(previousState: previousState, newState: newState)
    }
    
    /// Creates a command for horizontal flip toggle
    static func horizontalFlipToggle(currentState: CropRotateState) -> CropRotateCommand {
        let newState = currentState.withToggledHorizontalFlip()
        return CropRotateCommand(previousState: currentState, newState: newState)
    }
    
    /// Creates a command for vertical flip toggle
    static func verticalFlipToggle(currentState: CropRotateState) -> CropRotateCommand {
        let newState = currentState.withToggledVerticalFlip()
        return CropRotateCommand(previousState: currentState, newState: newState)
    }
    
    /// Creates a command for aspect ratio changes
    static func aspectRatioChange(from previousRatio: AspectRatio?, to newRatio: AspectRatio?, preservingState currentState: CropRotateState) -> CropRotateCommand {
        let previousState = currentState.withAspectRatio(previousRatio)
        let newState = currentState.withAspectRatio(newRatio)
        return CropRotateCommand(previousState: previousState, newState: newState)
    }
}

// MARK: - Command Validation

public extension CropRotateCommand {
    
    /// Validates that the command represents a meaningful change
    var isValidChange: Bool {
        return previousState != newState
    }
    
    /// Validates that both states are valid
    var hasValidStates: Bool {
        return previousState.isValid && newState.isValid
    }
    
    /// Returns a normalized version of this command with valid states
    func normalized() -> CropRotateCommand {
        return CropRotateCommand(
            previousState: previousState.normalized(),
            newState: newState.normalized()
        )
    }
}

// MARK: - Command Composition

public extension CropRotateCommand {
    
    /// Checks if this command can be coalesced with another crop/rotate command
    /// This is useful for reducing command history size during rapid changes
    func canCoalesce(with other: CropRotateCommand) -> Bool {
        // Can coalesce if the other command's previous state matches our new state
        // and they're close in time (within reasonable gesture duration)
        let timeDifference = abs(other.timestamp.timeIntervalSince(timestamp))
        return other.previousState == newState && timeDifference < 2.0 // 2 seconds
    }
    
    /// Creates a new command that represents the combined effect of this command and another
    func coalescing(with other: CropRotateCommand) -> CropRotateCommand? {
        guard canCoalesce(with: other) else { return nil }
        
        return CropRotateCommand(
            previousState: previousState,
            newState: other.newState
        )
    }
}

// MARK: - Helper Functions

private func separator(_ s: String) -> String { s } // Prevents SwiftLint issues with string literals