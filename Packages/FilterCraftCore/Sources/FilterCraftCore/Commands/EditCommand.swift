import Foundation

/// Base protocol for all editing commands in the undo/redo system
/// 
/// Commands represent individual edit operations that can be executed and reversed.
/// They store only the minimal data needed to perform the operation and its reversal,
/// making the history system memory-efficient.
public protocol EditCommand {
    /// Unique identifier for this command
    var id: UUID { get }
    
    /// Human-readable description for UI display (e.g., "Adjust Brightness", "Apply Vintage Filter")
    var description: String { get }
    
    /// Timestamp when command was created
    var timestamp: Date { get }
    
    /// Execute the command (apply the edit)
    /// This method should modify the EditSession state to apply the changes
    func execute(on session: EditSession) async
    
    /// Reverse the command (undo the edit)
    /// This method should restore the EditSession to its state before execute() was called
    func undo(on session: EditSession) async
    
    /// Estimated memory footprint in bytes for history management
    /// Used to determine when to prune old commands from history
    var memoryFootprint: Int { get }
}

/// Default implementations for common command functionality
public extension EditCommand {
    /// Default memory footprint calculation based on command description and data size
    var memoryFootprint: Int {
        // Base memory footprint includes UUID (16 bytes), Date (8 bytes), and description
        let baseSize = 16 + 8 + (description.utf8.count)
        
        // Add estimate for command-specific data (can be overridden by specific commands)
        return baseSize + estimatedDataSize
    }
    
    /// Override this in specific commands to provide accurate memory estimation
    var estimatedDataSize: Int { 100 } // Default 100 bytes for small data
}

/// Base implementation for commands that can be composed together
public protocol CompositeEditCommand: EditCommand {
    /// The sub-commands that make up this composite command
    var subCommands: [EditCommand] { get }
}

public extension CompositeEditCommand {
    var memoryFootprint: Int {
        let baseSize = 16 + 8 + description.utf8.count
        let subCommandsSize = subCommands.reduce(0) { $0 + $1.memoryFootprint }
        return baseSize + subCommandsSize
    }
    
    func execute(on session: EditSession) async {
        for command in subCommands {
            await command.execute(on: session)
        }
    }
    
    func undo(on session: EditSession) async {
        // Undo in reverse order
        for command in subCommands.reversed() {
            await command.undo(on: session)
        }
    }
}

/// Errors that can occur during command execution
public enum CommandExecutionError: LocalizedError {
    case executionFailed(String)
    case undoFailed(String)
    case invalidSessionState
    case commandDataCorrupted
    
    public var errorDescription: String? {
        switch self {
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        case .undoFailed(let message):
            return "Command undo failed: \(message)"
        case .invalidSessionState:
            return "Invalid session state for command"
        case .commandDataCorrupted:
            return "Command data is corrupted"
        }
    }
}