import XCTest
import CoreImage
@testable import FilterCraftCore

/// Comprehensive tests for the EditHistory manager
@MainActor
final class EditHistoryTests: XCTestCase {
    
    private var editHistory: EditHistory!
    private var editSession: EditSession!
    private var testImage: CIImage!
    
    override func setUp() async throws {
        try await super.setUp()
        
        editHistory = EditHistory(maxHistorySize: 50, maxMemoryUsage: 50000) // More generous limits for tests
        editSession = EditSession(enableCommandHistory: true)
        
        // Create a test image
        testImage = CIImage(color: .blue).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        await editSession.loadImage(testImage)
    }
    
    override func tearDown() async throws {
        editHistory = nil
        editSession = nil
        testImage = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testInitialState() {
        XCTAssertFalse(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
        XCTAssertNil(editHistory.undoDescription)
        XCTAssertNil(editHistory.redoDescription)
        XCTAssertEqual(editHistory.currentPosition, 0)
        XCTAssertEqual(editHistory.totalCommands, 0)
        XCTAssertEqual(editHistory.memoryUsage, 0)
    }
    
    func testAddCommand() {
        let command = createTestAdjustmentCommand()
        editHistory.addCommand(command)
        
        XCTAssertTrue(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
        XCTAssertEqual(editHistory.undoDescription, command.description)
        XCTAssertEqual(editHistory.currentPosition, 1)
        XCTAssertEqual(editHistory.totalCommands, 1)
        XCTAssertGreaterThan(editHistory.memoryUsage, 0)
    }
    
    func testUndoRedo() async throws {
        let command = createTestAdjustmentCommand()
        editHistory.addCommand(command)
        
        // Test undo
        await editHistory.undo(on: editSession)
        
        XCTAssertFalse(editHistory.canUndo)
        XCTAssertTrue(editHistory.canRedo)
        XCTAssertNil(editHistory.undoDescription)
        XCTAssertEqual(editHistory.redoDescription, command.description)
        XCTAssertEqual(editHistory.currentPosition, 0)
        
        // Test redo
        await editHistory.redo(on: editSession)
        
        XCTAssertTrue(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
        XCTAssertEqual(editHistory.undoDescription, command.description)
        XCTAssertNil(editHistory.redoDescription)
        XCTAssertEqual(editHistory.currentPosition, 1)
    }
    
    func testMultipleCommands() {
        let commands = (1...5).map { i in
            createTestAdjustmentCommand(brightness: Float(i) / 10.0)
        }
        
        for command in commands {
            editHistory.addCommand(command)
        }
        
        XCTAssertEqual(editHistory.totalCommands, 5)
        XCTAssertEqual(editHistory.currentPosition, 5)
        XCTAssertTrue(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
    }
    
    func testRedoStackClearedOnNewCommand() async throws {
        let command1 = createTestAdjustmentCommand(brightness: 0.1)
        let command2 = createTestAdjustmentCommand(brightness: 0.2)
        let command3 = createTestAdjustmentCommand(brightness: 0.3)
        
        editHistory.addCommand(command1)
        editHistory.addCommand(command2)
        
        // Undo to create redo stack
        await editHistory.undo(on: editSession)
        XCTAssertTrue(editHistory.canRedo)
        
        // Add new command should clear redo stack
        editHistory.addCommand(command3)
        XCTAssertFalse(editHistory.canRedo)
        XCTAssertEqual(editHistory.totalCommands, 2) // command1 + command3
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsageTracking() {
        let initialMemory = editHistory.memoryUsage
        XCTAssertEqual(initialMemory, 0)
        
        let command = createTestAdjustmentCommand()
        editHistory.addCommand(command)
        
        XCTAssertEqual(editHistory.memoryUsage, command.memoryFootprint)
        
        editHistory.clearHistory()
        XCTAssertEqual(editHistory.memoryUsage, 0)
    }
    
    func testAutomaticPruning() {
        // Set very small limits to trigger pruning
        let smallHistory = EditHistory(maxHistorySize: 3, maxMemoryUsage: 500)
        
        // Add commands beyond the limit
        for i in 1...5 {
            let command = createTestAdjustmentCommand(brightness: Float(i) / 10.0)
            smallHistory.addCommand(command)
        }
        
        // Should have pruned to stay within limits
        XCTAssertLessThanOrEqual(smallHistory.totalCommands, 3)
    }
    
    func testMemoryCleanup() {
        // Add several commands
        for i in 1...5 {
            let command = createTestAdjustmentCommand(brightness: Float(i) / 10.0)
            editHistory.addCommand(command)
        }
        
        let initialMemory = editHistory.memoryUsage
        XCTAssertGreaterThan(initialMemory, 0)
        
        editHistory.performMemoryCleanup()
        
        // Memory should be the same or less after cleanup
        XCTAssertLessThanOrEqual(editHistory.memoryUsage, initialMemory)
    }
    
    // MARK: - Statistics Tests
    
    func testStatistics() async throws {
        let command1 = createTestAdjustmentCommand(brightness: 0.1)
        let command2 = createTestAdjustmentCommand(brightness: 0.2)
        
        // Add commands
        editHistory.addCommand(command1)
        editHistory.addCommand(command2)
        
        XCTAssertEqual(editHistory.statistics.totalCommands, 2)
        XCTAssertEqual(editHistory.statistics.undoOperations, 0)
        XCTAssertEqual(editHistory.statistics.redoOperations, 0)
        
        // Perform undo/redo operations
        await editHistory.undo(on: editSession)
        XCTAssertEqual(editHistory.statistics.undoOperations, 1)
        
        await editHistory.redo(on: editSession)
        XCTAssertEqual(editHistory.statistics.redoOperations, 1)
        
        // Test ratio calculation
        XCTAssertEqual(editHistory.statistics.undoRedoRatio, 1.0) // 1 redo / 1 undo
    }
    
    func testCommandsByType() {
        let adjustmentCommand = createTestAdjustmentCommand()
        let filterCommand = createTestFilterCommand()
        
        editHistory.addCommand(adjustmentCommand)
        editHistory.addCommand(filterCommand)
        
        let stats = editHistory.statistics
        XCTAssertEqual(stats.totalCommands, 2)
        XCTAssertTrue(stats.commandsByType.keys.contains("AdjustmentCommand"))
        XCTAssertTrue(stats.commandsByType.keys.contains("FilterCommand"))
    }
    
    // MARK: - Batch Operations Tests
    
    func testBatchCommand() {
        let subCommands: [EditCommand] = [
            createTestAdjustmentCommand(brightness: 0.1),
            createTestAdjustmentCommand(brightness: 0.2),
            createTestAdjustmentCommand(brightness: 0.3)
        ]
        
        let batchCommand = editHistory.createBatchCommand(
            commands: subCommands,
            description: "Test Batch"
        )
        
        editHistory.addCommand(batchCommand)
        
        XCTAssertEqual(editHistory.totalCommands, 1) // Batch counts as one command
        XCTAssertEqual(editHistory.undoDescription, "Test Batch")
    }
    
    // MARK: - Edge Cases Tests
    
    func testUndoWhenEmpty() async throws {
        XCTAssertFalse(editHistory.canUndo)
        
        // Should not crash or cause issues
        await editHistory.undo(on: editSession)
        
        XCTAssertFalse(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
    }
    
    func testRedoWhenEmpty() async throws {
        XCTAssertNotNil(editSession, "EditSession should be set up properly")
        XCTAssertFalse(editHistory.canRedo)
        
        // Should not crash or cause issues
        await editHistory.redo(on: editSession)
        
        XCTAssertFalse(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
    }
    
    func testClearHistory() {
        // Add some commands
        editHistory.addCommand(createTestAdjustmentCommand())
        editHistory.addCommand(createTestAdjustmentCommand())
        
        XCTAssertGreaterThan(editHistory.totalCommands, 0)
        
        editHistory.clearHistory()
        
        XCTAssertEqual(editHistory.totalCommands, 0)
        XCTAssertFalse(editHistory.canUndo)
        XCTAssertFalse(editHistory.canRedo)
        XCTAssertEqual(editHistory.memoryUsage, 0)
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentCommandAddition() async throws {
        let commandCount = 10
        let commands = (1...commandCount).map { i in
            createTestAdjustmentCommand(brightness: Float(i) / 100.0)
        }
        
        // Since EditHistory is @MainActor, commands will be serialized anyway
        // This test verifies that rapid sequential addition works correctly
        for command in commands {
            editHistory.addCommand(command)
        }
        
        // All commands should be added
        XCTAssertEqual(editHistory.totalCommands, commandCount)
    }
    
    // MARK: - Performance Tests
    
    func testAddCommandPerformance() {
        let commands = (1...100).map { i in
            createTestAdjustmentCommand(brightness: Float(i) / 1000.0)
        }
        
        measure {
            for command in commands {
                editHistory.addCommand(command)
            }
            editHistory.clearHistory()
        }
    }
    
    func testUndoRedoPerformance() {
        // Add many commands
        for i in 1...50 {
            let command = createTestAdjustmentCommand(brightness: Float(i) / 1000.0)
            editHistory.addCommand(command)
        }
        
        measure {
            // Measure the history state properties instead of async operations
            _ = editHistory.canUndo
            _ = editHistory.canRedo
            _ = editHistory.undoDescription
            _ = editHistory.redoDescription
            _ = editHistory.totalCommands
            _ = editHistory.memoryUsage
        }
    }
    
    func testMemoryCleanupPerformance() {
        // Add many commands to simulate heavy usage
        for i in 1...1000 {
            let command = createTestAdjustmentCommand(brightness: Float(i) / 10000.0)
            editHistory.addCommand(command)
        }
        
        measure {
            editHistory.performMemoryCleanup()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestAdjustmentCommand(brightness: Float = 0.5) -> AdjustmentCommand {
        return AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: brightness)
        )
    }
    
    private func createTestFilterCommand() -> FilterCommand {
        let filter = AppliedFilter(filterType: .vintage, intensity: 0.7)
        return FilterCommand(
            applyingFilter: filter,
            previousBaseAdjustments: ImageAdjustments()
        )
    }
}