import XCTest
import CoreImage
@testable import FilterCraftCore

/// Comprehensive tests for the EditCommand protocol and command system
@MainActor
final class EditCommandTests: XCTestCase {
    
    private var editSession: EditSession!
    private var testImage: CIImage!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test edit session with command history enabled
        editSession = EditSession(enableCommandHistory: true)
        
        // Create a test image
        testImage = CIImage(color: .red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        await editSession.loadImage(testImage)
    }
    
    override func tearDown() async throws {
        editSession = nil
        testImage = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Command Functionality Tests
    
    func testAdjustmentCommandExecuteAndUndo() async throws {
        let originalAdjustments = editSession.userAdjustments
        let newAdjustments = ImageAdjustments(brightness: 0.5, contrast: 0.3)
        
        let command = AdjustmentCommand(
            previousUserAdjustments: originalAdjustments,
            newUserAdjustments: newAdjustments
        )
        
        // Test execute
        await command.execute(on: editSession)
        XCTAssertEqual(editSession.userAdjustments.brightness, 0.5)
        XCTAssertEqual(editSession.userAdjustments.contrast, 0.3)
        
        // Test undo
        await command.undo(on: editSession)
        XCTAssertEqual(editSession.userAdjustments, originalAdjustments)
    }
    
    func testFilterCommandExecuteAndUndo() async throws {
        let originalFilter = editSession.appliedFilter
        let originalBaseAdjustments = editSession.baseAdjustments
        let newFilter = AppliedFilter(filterType: .vintage, intensity: 0.8)
        
        let command = FilterCommand(
            applyingFilter: newFilter,
            previousBaseAdjustments: originalBaseAdjustments
        )
        
        // Test execute
        await command.execute(on: editSession)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .vintage)
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.8)
        XCTAssertNotEqual(editSession.baseAdjustments, originalBaseAdjustments)
        
        // Test undo
        await command.undo(on: editSession)
        XCTAssertEqual(editSession.appliedFilter, originalFilter)
        XCTAssertEqual(editSession.baseAdjustments, originalBaseAdjustments)
    }
    
    func testResetCommandExecuteAndUndo() async throws {
        // Set up some edits
        editSession.userAdjustments = ImageAdjustments(brightness: 0.5)
        editSession.appliedFilter = AppliedFilter(filterType: .sepia)
        
        let command = ResetCommand(completeResetFrom: editSession)
        
        // Test execute (should reset everything)
        await command.execute(on: editSession)
        XCTAssertEqual(editSession.userAdjustments, ImageAdjustments())
        XCTAssertEqual(editSession.baseAdjustments, ImageAdjustments())
        XCTAssertNil(editSession.appliedFilter)
        
        // Test undo (should restore everything)
        await command.undo(on: editSession)
        XCTAssertEqual(editSession.userAdjustments.brightness, 0.5)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .sepia)
    }
    
    // MARK: - Memory Footprint Tests
    
    func testCommandMemoryFootprint() {
        let adjustments1 = ImageAdjustments(brightness: 0.5)
        let adjustments2 = ImageAdjustments(contrast: 0.3)
        
        let command = AdjustmentCommand(
            previousUserAdjustments: adjustments1,
            newUserAdjustments: adjustments2
        )
        
        // Memory footprint should be reasonable (less than 1KB for simple commands)
        XCTAssertLessThan(command.memoryFootprint, 1000)
        XCTAssertGreaterThan(command.memoryFootprint, 0)
    }
    
    func testBatchCommandMemoryFootprint() {
        let commands: [EditCommand] = [
            AdjustmentCommand(
                previousUserAdjustments: ImageAdjustments(),
                newUserAdjustments: ImageAdjustments(brightness: 0.5)
            ),
            AdjustmentCommand(
                previousUserAdjustments: ImageAdjustments(brightness: 0.5),
                newUserAdjustments: ImageAdjustments(brightness: 0.5, contrast: 0.3)
            )
        ]
        
        let batchCommand = BatchEditCommand(commands: commands, description: "Batch test")
        
        // Batch command memory should be sum of sub-commands plus overhead
        let expectedMemory = commands.reduce(0) { $0 + $1.memoryFootprint }
        XCTAssertGreaterThan(batchCommand.memoryFootprint, expectedMemory)
    }
    
    // MARK: - Command Description Tests
    
    func testAdjustmentCommandDescription() {
        let command = AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: 0.5)
        )
        
        XCTAssertTrue(command.description.contains("Adjust"))
        XCTAssertTrue(command.description.lowercased().contains("brightness"))
    }
    
    func testFilterCommandDescription() {
        let filter = AppliedFilter(filterType: .vintage, intensity: 0.8)
        let command = FilterCommand(
            applyingFilter: filter,
            previousBaseAdjustments: ImageAdjustments()
        )
        
        XCTAssertTrue(command.description.contains("Vintage"))
    }
    
    // MARK: - Edge Cases
    
    func testCommandWithNoChanges() async throws {
        let sameAdjustments = ImageAdjustments(brightness: 0.5)
        
        let command = AdjustmentCommand(
            previousUserAdjustments: sameAdjustments,
            newUserAdjustments: sameAdjustments
        )
        
        // Execute should work even with no actual changes
        await command.execute(on: editSession)
        await command.undo(on: editSession)
        
        // Should not cause any issues
        XCTAssertEqual(editSession.userAdjustments, sameAdjustments)
    }
    
    func testCommandTimestamp() {
        let beforeTime = Date()
        let command = AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: 0.5)
        )
        let afterTime = Date()
        
        XCTAssertGreaterThanOrEqual(command.timestamp, beforeTime)
        XCTAssertLessThanOrEqual(command.timestamp, afterTime)
    }
    
    func testCommandUniqueIdentifiers() {
        let command1 = AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: 0.5)
        )
        
        let command2 = AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: 0.5)
        )
        
        // Each command should have a unique ID
        XCTAssertNotEqual(command1.id, command2.id)
    }
    
    // MARK: - Complex Command Tests
    
    func testFilterIntensityCommand() async throws {
        // First apply a filter
        editSession.applyFilter(.vibrant, intensity: 0.5)
        
        // Wait for the filter to be applied
        try await Task.sleep(nanoseconds: 100_000_000)
        
        guard let filter = editSession.appliedFilter else {
            XCTFail("Filter was not applied")
            return
        }
        
        // Now test intensity change command
        let command = FilterCommand(
            changingIntensityOf: filter,
            from: 0.5,
            to: 0.8,
            previousBaseAdjustments: editSession.baseAdjustments
        )
        
        await command.execute(on: editSession)
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.8)
        
        await command.undo(on: editSession)
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.5)
    }
    
    func testSmartResetCommand() async throws {
        // Set up complex editing state
        editSession.userAdjustments = ImageAdjustments(brightness: 0.8, contrast: 0.5)
        editSession.appliedFilter = AppliedFilter(filterType: .dramatic, intensity: 0.9)
        
        let command = SmartResetCommand(smartResetFrom: editSession)
        
        // Smart reset should analyze and reset appropriately
        await command.execute(on: editSession)
        
        // Should have reset everything due to significant changes
        XCTAssertFalse(editSession.hasEdits)
        
        // Undo should restore everything
        await command.undo(on: editSession)
        XCTAssertEqual(editSession.userAdjustments.brightness, 0.8)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .dramatic)
    }
    
    // MARK: - Performance Tests
    
    func testCommandExecutionPerformance() {
        let command = AdjustmentCommand(
            previousUserAdjustments: ImageAdjustments(),
            newUserAdjustments: ImageAdjustments(brightness: 0.5)
        )
        
        measure {
            // Measure the command creation and properties, not async execution
            _ = command.memoryFootprint
            _ = command.description
            _ = command.id
        }
    }
    
    func testBatchCommandPerformance() {
        let commands: [EditCommand] = (0..<100).map { i in
            AdjustmentCommand(
                previousUserAdjustments: ImageAdjustments(),
                newUserAdjustments: ImageAdjustments(brightness: Float(i) / 1000.0)
            )
        }
        
        measure {
            // Measure batch command creation and memory footprint calculation
            let batchCommand = BatchEditCommand(commands: commands, description: "Performance test")
            _ = batchCommand.memoryFootprint
            _ = batchCommand.description
        }
    }
}

// MARK: - Mock Commands for Testing

/// Mock command for testing composite functionality
private class MockCommand: EditCommand {
    let id = UUID()
    let timestamp = Date()
    let description = "Mock Command"
    var executeCallCount = 0
    var undoCallCount = 0
    
    func execute(on session: EditSession) async {
        executeCallCount += 1
    }
    
    func undo(on session: EditSession) async {
        undoCallCount += 1
    }
    
    var estimatedDataSize: Int { 50 }
}

/// Mock composite command for testing
private struct MockCompositeCommand: CompositeEditCommand {
    let id = UUID()
    let timestamp = Date()
    let description = "Mock Composite"
    let subCommands: [EditCommand]
    
    init(commands: [EditCommand]) {
        self.subCommands = commands
    }
}