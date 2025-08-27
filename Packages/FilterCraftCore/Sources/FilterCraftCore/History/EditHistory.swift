import Foundation
import Combine

/// Memory-efficient history manager for undo/redo operations
///
/// This class manages the command history with smart memory management,
/// automatic pruning, and comprehensive state tracking for UI updates.
@MainActor
public class EditHistory: ObservableObject {
    
    // MARK: - Published Properties for UI Binding
    
    /// Whether undo is available
    @Published public private(set) var canUndo: Bool = false
    
    /// Whether redo is available
    @Published public private(set) var canRedo: Bool = false
    
    /// Description of the next undo operation (for UI display)
    @Published public private(set) var undoDescription: String?
    
    /// Description of the next redo operation (for UI display)
    @Published public private(set) var redoDescription: String?
    
    /// Current history position (for UI indicators)
    @Published public private(set) var currentPosition: Int = 0
    
    /// Total number of commands in history
    @Published public private(set) var totalCommands: Int = 0
    
    /// Current memory usage in bytes
    @Published public private(set) var memoryUsage: Int = 0
    
    /// History statistics for analytics
    @Published public private(set) var statistics = HistoryStatistics()
    
    // MARK: - Private Properties
    
    private var undoStack: [EditCommand] = []
    private var redoStack: [EditCommand] = []
    
    // Configuration
    private let maxHistorySize: Int
    private let maxMemoryUsage: Int
    private let pruningThreshold: Int
    
    // Memory management
    private var memoryPressureHandler: (() -> Void)?
    private var backgroundCleanupTimer: Timer?
    private let cleanupInterval: TimeInterval = 30.0 // 30 seconds
    
    // Performance tracking
    private var lastOperationTime: Date = Date()
    private var operationCount: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a new EditHistory manager with specified limits
    /// - Parameters:
    ///   - maxHistorySize: Maximum number of commands to keep (default: 50)
    ///   - maxMemoryUsage: Maximum memory usage in bytes (default: 100MB)
    ///   - enableBackgroundCleanup: Whether to enable automatic cleanup (default: true)
    public init(
        maxHistorySize: Int = 50,
        maxMemoryUsage: Int = 100_000_000, // 100MB
        enableBackgroundCleanup: Bool = true
    ) {
        self.maxHistorySize = maxHistorySize
        self.maxMemoryUsage = maxMemoryUsage
        self.pruningThreshold = maxHistorySize / 4 // Start pruning at 25% capacity
        
        updateUIState()
        
        if enableBackgroundCleanup {
            startBackgroundCleanup()
        }
    }
    
    deinit {
        backgroundCleanupTimer?.invalidate()
        backgroundCleanupTimer = nil
    }
    
    // MARK: - Public Methods
    
    /// Adds a new command to the history
    /// - Parameter command: The command to add
    public func addCommand(_ command: EditCommand) {
        // Clear redo stack when adding new command
        redoStack.removeAll()
        
        // Add command to undo stack
        undoStack.append(command)
        
        // Update memory usage
        memoryUsage += command.memoryFootprint
        
        // Prune if necessary
        pruneHistoryIfNeeded()
        
        // Update statistics
        statistics.recordCommand(command)
        operationCount += 1
        lastOperationTime = Date()
        
        updateUIState()
    }
    
    /// Performs an undo operation
    /// - Parameter session: The EditSession to perform the undo on
    public func undo(on session: EditSession) async {
        guard !undoStack.isEmpty else { return }
        
        let command = undoStack.removeLast()
        
        await command.undo(on: session)
        
        // Move command to redo stack
        redoStack.append(command)
        
        // Update memory usage (command moved from undo to redo, no change)
        
        // Update statistics
        statistics.recordUndo()
        
        updateUIState()
    }
    
    /// Performs a redo operation
    /// - Parameter session: The EditSession to perform the redo on
    public func redo(on session: EditSession) async {
        guard !redoStack.isEmpty else { return }
        
        let command = redoStack.removeLast()
        
        await command.execute(on: session)
        
        // Move command back to undo stack
        undoStack.append(command)
        
        // Update memory usage (command moved from redo to undo, no change)
        
        // Update statistics
        statistics.recordRedo()
        
        updateUIState()
    }
    
    /// Clears all history
    public func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        memoryUsage = 0
        statistics = HistoryStatistics()
        updateUIState()
    }
    
    /// Forces a memory cleanup operation
    public func performMemoryCleanup() {
        pruneOldCommands()
        updateUIState()
    }
    
    /// Gets a snapshot of the current history state
    public func getHistorySnapshot() -> HistorySnapshot {
        return HistorySnapshot(
            undoStack: undoStack,
            redoStack: redoStack,
            currentPosition: currentPosition,
            memoryUsage: memoryUsage,
            statistics: statistics
        )
    }
    
    /// Creates a batch of commands that can be undone as a single operation
    /// - Parameter commands: The commands to batch together
    /// - Parameter description: Description for the batch operation
    /// - Returns: A composite command representing the batch
    public func createBatchCommand(
        commands: [EditCommand],
        description: String
    ) -> any EditCommand {
        return BatchEditCommand(commands: commands, description: description)
    }
    
    // MARK: - Memory Management
    
    private func pruneHistoryIfNeeded() {
        // Check if we need to prune based on size or memory
        let needsPruning = undoStack.count > maxHistorySize ||
                          memoryUsage > maxMemoryUsage ||
                          (undoStack.count > pruningThreshold && shouldPruneForPerformance())
        
        if needsPruning {
            pruneHistory()
        }
    }
    
    private func pruneHistory() {
        let targetSize = max(maxHistorySize * 3 / 4, 10) // Keep 75% of max size, minimum 10
        let targetMemory = maxMemoryUsage * 3 / 4 // Keep 75% of max memory
        
        // Remove oldest commands first
        while (undoStack.count > targetSize || memoryUsage > targetMemory) && !undoStack.isEmpty {
            let removedCommand = undoStack.removeFirst()
            memoryUsage -= removedCommand.memoryFootprint
            statistics.recordPrunedCommand()
        }
        
        // Also clear some redo stack if it's large
        if redoStack.count > 20 {
            let removeCount = redoStack.count - 15
            for _ in 0..<removeCount {
                let removedCommand = redoStack.removeFirst()
                memoryUsage -= removedCommand.memoryFootprint
            }
        }
    }
    
    private func pruneOldCommands() {
        let oldThreshold = Date().addingTimeInterval(-300) // 5 minutes ago
        
        // Remove old commands from the beginning of undo stack
        while let firstCommand = undoStack.first,
              firstCommand.timestamp < oldThreshold,
              undoStack.count > 5 { // Keep at least 5 commands
            let removedCommand = undoStack.removeFirst()
            memoryUsage -= removedCommand.memoryFootprint
        }
        
        // Clear old redo commands more aggressively
        redoStack.removeAll { $0.timestamp < oldThreshold }
        recalculateMemoryUsage()
    }
    
    private func shouldPruneForPerformance() -> Bool {
        // Prune if we have many recent operations (might indicate rapid changes)
        let recentThreshold = Date().addingTimeInterval(-10) // Last 10 seconds
        return lastOperationTime > recentThreshold && operationCount > 20
    }
    
    private func recalculateMemoryUsage() {
        memoryUsage = undoStack.reduce(0) { $0 + $1.memoryFootprint } +
                     redoStack.reduce(0) { $0 + $1.memoryFootprint }
    }
    
    // MARK: - Background Cleanup
    
    private func startBackgroundCleanup() {
        backgroundCleanupTimer = Timer.scheduledTimer(withTimeInterval: cleanupInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performBackgroundCleanup()
            }
        }
    }
    
    private func stopBackgroundCleanup() {
        backgroundCleanupTimer?.invalidate()
        backgroundCleanupTimer = nil
    }
    
    private func performBackgroundCleanup() {
        // Only cleanup if we haven't had recent operations
        let recentThreshold = Date().addingTimeInterval(-60) // 1 minute
        if lastOperationTime < recentThreshold {
            pruneOldCommands()
            updateUIState()
        }
    }
    
    // MARK: - UI State Management
    
    private func updateUIState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
        
        undoDescription = undoStack.last?.description
        redoDescription = redoStack.last?.description
        
        currentPosition = undoStack.count
        totalCommands = undoStack.count + redoStack.count
        
        // Trigger memory pressure handler if needed
        if memoryUsage > maxMemoryUsage * 4 / 5 { // 80% of limit
            memoryPressureHandler?()
        }
    }
    
    /// Sets a handler for memory pressure events
    public func setMemoryPressureHandler(_ handler: @escaping () -> Void) {
        memoryPressureHandler = handler
    }
}

// MARK: - Supporting Types

/// Statistics about the editing history
public struct HistoryStatistics {
    public private(set) var totalCommands: Int = 0
    public private(set) var undoOperations: Int = 0
    public private(set) var redoOperations: Int = 0
    public private(set) var prunedCommands: Int = 0
    public private(set) var commandsByType: [String: Int] = [:]
    public private(set) var sessionStartTime = Date()
    
    public var undoRedoRatio: Double {
        guard undoOperations > 0 else { return 0.0 }
        return Double(redoOperations) / Double(undoOperations)
    }
    
    public var averageCommandsPerMinute: Double {
        let sessionDuration = Date().timeIntervalSince(sessionStartTime) / 60.0
        guard sessionDuration > 0 else { return 0.0 }
        return Double(totalCommands) / sessionDuration
    }
    
    mutating func recordCommand(_ command: EditCommand) {
        totalCommands += 1
        let commandType = String(describing: type(of: command))
        commandsByType[commandType, default: 0] += 1
    }
    
    mutating func recordUndo() {
        undoOperations += 1
    }
    
    mutating func recordRedo() {
        redoOperations += 1
    }
    
    mutating func recordPrunedCommand() {
        prunedCommands += 1
    }
}

/// Snapshot of the current history state
public struct HistorySnapshot {
    public let undoStack: [EditCommand]
    public let redoStack: [EditCommand]
    public let currentPosition: Int
    public let memoryUsage: Int
    public let statistics: HistoryStatistics
    
    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }
    public var totalCommands: Int { undoStack.count + redoStack.count }
}

/// Composite command for batching multiple commands together
public struct BatchEditCommand: CompositeEditCommand {
    public let id: UUID
    public let timestamp: Date
    public let description: String
    public let subCommands: [EditCommand]
    
    public init(commands: [EditCommand], description: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.description = description
        self.subCommands = commands
    }
}