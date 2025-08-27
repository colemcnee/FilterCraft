import XCTest
import CoreImage
@testable import FilterCraftCore

@MainActor
final class EditSessionTests: XCTestCase {
    
    private var editSession: EditSession!
    private var mockProcessor: MockImageProcessor!
    private var testImage: CIImage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockProcessor = MockImageProcessor()
        editSession = EditSession(imageProcessor: mockProcessor)
        
        // Create a test image
        testImage = CIImage(color: CIColor.blue).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))
    }
    
    override func tearDownWithError() throws {
        editSession = nil
        mockProcessor = nil
        testImage = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertEqual(editSession.processingState, .idle)
        XCTAssertNil(editSession.originalImage)
        XCTAssertNil(editSession.previewImage)
        XCTAssertNil(editSession.fullResolutionImage)
        XCTAssertNil(editSession.appliedFilter)
        XCTAssertFalse(editSession.adjustments.hasAdjustments)
        XCTAssertFalse(editSession.hasEdits)
        XCTAssertTrue(editSession.editHistory.isEmpty)
        XCTAssertEqual(editSession.imageExtent, .zero)
    }
    
    // MARK: - Image Loading Tests
    
    func testLoadImage() async {
        await editSession.loadImage(testImage)
        
        XCTAssertEqual(editSession.originalImage, testImage)
        XCTAssertEqual(editSession.fullResolutionImage, testImage)
        XCTAssertNotNil(editSession.previewImage)
        XCTAssertEqual(editSession.processingState, .completed)
        XCTAssertFalse(editSession.hasEdits) // No edits initially
        XCTAssertFalse(editSession.editHistory.isEmpty) // Should have load operation
        XCTAssertEqual(editSession.imageExtent, testImage.extent)
        
        // Check that load operation was recorded
        let loadOperations = editSession.editHistory.filter { $0.type == .imageLoad }
        XCTAssertEqual(loadOperations.count, 1)
    }
    
    func testLoadImageResetsSession() async {
        // First, make some edits
        await editSession.loadImage(testImage)
        editSession.applyFilter(.sepia, intensity: 0.8)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.5))
        
        XCTAssertTrue(editSession.hasEdits)
        
        // Load a new image
        let newImage = CIImage(color: CIColor.red).cropped(to: CGRect(x: 0, y: 0, width: 300, height: 300))
        await editSession.loadImage(newImage)
        
        // Session should be reset
        XCTAssertFalse(editSession.hasEdits)
        XCTAssertFalse(editSession.adjustments.hasAdjustments)
        XCTAssertNil(editSession.appliedFilter)
        XCTAssertEqual(editSession.originalImage, newImage)
        XCTAssertEqual(editSession.fullResolutionImage, newImage)
    }
    
    // MARK: - Adjustments Tests
    
    func testUpdateAdjustments() async {
        await editSession.loadImage(testImage)
        
        let adjustments = ImageAdjustments(brightness: 0.3, contrast: 0.2, saturation: 0.1)
        editSession.updateAdjustments(adjustments)
        
        XCTAssertEqual(editSession.adjustments.brightness, 0.3)
        XCTAssertEqual(editSession.adjustments.contrast, 0.2)
        XCTAssertEqual(editSession.adjustments.saturation, 0.1)
        XCTAssertTrue(editSession.hasEdits)
        
        // Check that adjustment operation was recorded
        let adjustmentOperations = editSession.editHistory.filter { $0.type == .adjustmentChange }
        XCTAssertTrue(adjustmentOperations.count > 0)
    }
    
    func testAdjustmentsUpdateTriggersPreviewUpdate() async {
        await editSession.loadImage(testImage)
        
        let initialOperationCount = mockProcessor.processingDelay == 0.1 ? 1 : 0 // Account for initial load
        
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.5
        editSession.updateAdjustments(adjustments)
        
        // Wait a moment for async processing
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        XCTAssertTrue(editSession.sessionStats.operationCount > initialOperationCount)
    }
    
    // MARK: - Filter Tests
    
    func testApplyFilter() async {
        await editSession.loadImage(testImage)
        
        editSession.applyFilter(.vintage, intensity: 0.8)
        
        XCTAssertNotNil(editSession.appliedFilter)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .vintage)
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.8)
        XCTAssertTrue(editSession.hasEdits)
        
        // Check that filter operation was recorded
        let filterOperations = editSession.editHistory.filter { $0.type == .filterApplication }
        XCTAssertTrue(filterOperations.count > 0)
    }
    
    func testApplyFilterWithDefaultIntensity() async {
        await editSession.loadImage(testImage)
        
        editSession.applyFilter(.dramatic)
        
        XCTAssertEqual(editSession.appliedFilter?.filterType, .dramatic)
        XCTAssertEqual(editSession.appliedFilter?.intensity, FilterType.dramatic.defaultIntensity)
    }
    
    func testUpdateFilterIntensity() async {
        await editSession.loadImage(testImage)
        editSession.applyFilter(.sepia, intensity: 0.5)
        
        let originalFilterId = editSession.appliedFilter?.id
        
        editSession.updateFilterIntensity(0.9)
        
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.9)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .sepia)
        XCTAssertEqual(editSession.appliedFilter?.id, originalFilterId) // Should maintain same ID
    }
    
    func testUpdateFilterIntensityWithoutFilter() async {
        await editSession.loadImage(testImage)
        
        editSession.updateFilterIntensity(0.8)
        
        XCTAssertNil(editSession.appliedFilter) // Should remain nil
    }
    
    func testApplyNoneFilterRemovesFilter() async {
        await editSession.loadImage(testImage)
        editSession.applyFilter(.vintage, intensity: 0.8)
        
        XCTAssertNotNil(editSession.appliedFilter)
        
        editSession.applyFilter(.none)
        
        XCTAssertNotNil(editSession.appliedFilter) // AppliedFilter exists
        XCTAssertEqual(editSession.appliedFilter?.filterType, FilterType.none) // But is none type
        XCTAssertFalse(editSession.appliedFilter?.isEffective ?? true) // And not effective
    }
    
    // MARK: - Reset Tests
    
    func testResetToOriginal() async {
        await editSession.loadImage(testImage)
        
        // Make some edits
        editSession.applyFilter(.dramatic, intensity: 0.9)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.4, saturation: 0.2))
        
        XCTAssertTrue(editSession.hasEdits)
        
        await editSession.resetToOriginal()
        
        XCTAssertFalse(editSession.hasEdits)
        XCTAssertFalse(editSession.adjustments.hasAdjustments)
        XCTAssertNil(editSession.appliedFilter)
        XCTAssertEqual(editSession.fullResolutionImage, editSession.originalImage)
        
        // Check that reset operation was recorded
        let resetOperations = editSession.editHistory.filter { $0.type == .reset }
        XCTAssertEqual(resetOperations.count, 1)
    }
    
    // MARK: - Combined Edits Tests
    
    func testHasEditsWithAdjustmentsOnly() async {
        await editSession.loadImage(testImage)
        
        XCTAssertFalse(editSession.hasEdits)
        
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.1))
        
        XCTAssertTrue(editSession.hasEdits)
    }
    
    func testHasEditsWithFilterOnly() async {
        await editSession.loadImage(testImage)
        
        XCTAssertFalse(editSession.hasEdits)
        
        editSession.applyFilter(.sepia, intensity: 0.8)
        
        XCTAssertTrue(editSession.hasEdits)
    }
    
    func testHasEditsWithIneffectiveFilter() async {
        await editSession.loadImage(testImage)
        
        editSession.applyFilter(.vintage, intensity: 0.0) // Zero intensity
        
        XCTAssertFalse(editSession.hasEdits) // Should not count as edit
    }
    
    func testHasEditsWithNoneFilter() async {
        await editSession.loadImage(testImage)
        
        editSession.applyFilter(.none)
        
        XCTAssertFalse(editSession.hasEdits) // None filter doesn't count as edit
    }
    
    // MARK: - Export Tests
    
    func testGetFinalImage() async {
        await editSession.loadImage(testImage)
        
        editSession.applyFilter(.vintage, intensity: 0.8)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.2))
        
        let finalImage = await editSession.getFinalImage()
        
        XCTAssertNotNil(finalImage)
        XCTAssertEqual(editSession.processingState, .completed)
    }
    
    func testGetFinalImageWithoutOriginal() async {
        let finalImage = await editSession.getFinalImage()
        
        XCTAssertNil(finalImage)
    }
    
    func testExportImage() async {
        await editSession.loadImage(testImage)
        editSession.applyFilter(.sepia, intensity: 0.9)
        
        let exportData = await editSession.exportImage(format: .jpeg, quality: 0.8)
        
        XCTAssertNotNil(exportData)
        XCTAssertEqual(editSession.processingState, .completed)
        XCTAssertEqual(editSession.sessionStats.exportCount, 1)
    }
    
    func testExportImageWithoutEdits() async {
        await editSession.loadImage(testImage)
        
        let exportData = await editSession.exportImage(format: .png)
        
        XCTAssertNotNil(exportData) // Should still export original
    }
    
    func testExportImageWithoutOriginal() async {
        let exportData = await editSession.exportImage(format: .jpeg)
        
        XCTAssertNil(exportData) // Should fail without image
        XCTAssertEqual(editSession.processingState, .failed(ImageProcessingError.exportFailed))
    }
    
    // MARK: - Processing State Tests
    
    func testProcessingStateProgression() async {
        XCTAssertEqual(editSession.processingState, .idle)
        
        await editSession.loadImage(testImage)
        
        XCTAssertEqual(editSession.processingState, .completed)
    }
    
    func testGetProcessingProgress() async {
        XCTAssertEqual(editSession.getProcessingProgress(), 0.0)
        
        await editSession.loadImage(testImage)
        
        XCTAssertEqual(editSession.getProcessingProgress(), 1.0) // Should be completed
    }
    
    func testGetCurrentOperation() async {
        XCTAssertNil(editSession.getCurrentOperation())
        
        await editSession.loadImage(testImage)
        
        XCTAssertNil(editSession.getCurrentOperation()) // Should be nil when completed
    }
    
    // MARK: - Session Statistics Tests
    
    func testSessionStatisticsInitialization() async {
        XCTAssertEqual(editSession.sessionStats.operationCount, 0)
        XCTAssertEqual(editSession.sessionStats.exportCount, 0)
        XCTAssertTrue(editSession.sessionStats.operationsByType.isEmpty)
        XCTAssertGreaterThan(editSession.sessionStats.sessionDuration, 0)
    }
    
    func testSessionStatisticsTracking() async {
        await editSession.loadImage(testImage)
        
        let initialCount = editSession.sessionStats.operationCount
        
        editSession.applyFilter(.vintage, intensity: 0.8)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.3))
        
        // Wait for async operations to complete
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        XCTAssertGreaterThan(editSession.sessionStats.operationCount, initialCount)
    }
    
    func testFormattedSessionDuration() async {
        let formattedDuration = editSession.sessionStats.formattedSessionDuration
        
        // Should be in format "0:XX" or similar
        XCTAssertTrue(formattedDuration.contains(":"))
        XCTAssertTrue(formattedDuration.count >= 4) // At least "0:00"
    }
    
    // MARK: - Edit History Tests
    
    func testEditHistoryRecording() async {
        await editSession.loadImage(testImage)
        
        let initialHistoryCount = editSession.editHistory.count
        
        editSession.applyFilter(.dramatic, intensity: 0.7)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.2))
        await editSession.resetToOriginal()
        
        XCTAssertGreaterThan(editSession.editHistory.count, initialHistoryCount)
        
        // Check for specific operation types
        let loadOps = editSession.editHistory.filter { $0.type == .imageLoad }
        let filterOps = editSession.editHistory.filter { $0.type == .filterApplication }
        let adjustOps = editSession.editHistory.filter { $0.type == .adjustmentChange }
        let resetOps = editSession.editHistory.filter { $0.type == .reset }
        
        XCTAssertGreaterThanOrEqual(loadOps.count, 1)
        XCTAssertGreaterThanOrEqual(filterOps.count, 1)
        XCTAssertGreaterThanOrEqual(adjustOps.count, 1)
        XCTAssertGreaterThanOrEqual(resetOps.count, 1)
    }
    
    func testEditHistoryLimit() async {
        await editSession.loadImage(testImage)
        
        // Create many operations to test history limit
        for i in 0..<60 {
            editSession.updateAdjustments(ImageAdjustments(brightness: Float(i) * 0.01))
        }
        
        // History should be limited to 50 operations
        XCTAssertTrue(editSession.editHistory.count <= 50)
    }
    
    // MARK: - Mock Processor Tests
    
    func testMockProcessorFailureHandling() async {
        mockProcessor.shouldFail = true
        
        await editSession.loadImage(testImage)
        
        // Should handle failure gracefully
        XCTAssertNotNil(editSession.originalImage) // Original should still be set
        // Preview might be nil due to mock failure, but shouldn't crash
    }
    
    func testMockProcessorDelayHandling() async {
        mockProcessor.processingDelay = 0.5 // 0.5 second delay
        
        let startTime = CFAbsoluteTimeGetCurrent()
        await editSession.loadImage(testImage)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertGreaterThanOrEqual(timeElapsed, 0.4) // Should take at least the delay time
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAdjustmentUpdates() async {
        await editSession.loadImage(testImage)
        
        // Launch multiple concurrent adjustment updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask { @MainActor in
                    let brightness = Float(i) * 0.1
                    self.editSession.updateAdjustments(ImageAdjustments(brightness: brightness))
                }
            }
        }
        
        // Should handle concurrent updates without crashing
        XCTAssertTrue(editSession.adjustments.hasAdjustments)
    }
    
    func testConcurrentFilterApplications() async {
        await editSession.loadImage(testImage)
        
        let filters: [FilterType] = [.vintage, .sepia, .dramatic, .cool, .warm]
        
        // Apply filters concurrently (though they'll be processed sequentially due to @MainActor)
        await withTaskGroup(of: Void.self) { group in
            for filter in filters {
                group.addTask { @MainActor in
                    self.editSession.applyFilter(filter, intensity: 0.8)
                }
            }
        }
        
        // Should have the last applied filter
        XCTAssertNotNil(editSession.appliedFilter)
        XCTAssertTrue(filters.contains(editSession.appliedFilter!.filterType))
    }
    
    // MARK: - Edge Cases
    
    func testResetWithoutImage() async {
        await editSession.resetToOriginal()
        
        // Should handle gracefully
        XCTAssertFalse(editSession.hasEdits)
        XCTAssertNil(editSession.originalImage)
    }
    
    func testExportWithMockFailure() async {
        await editSession.loadImage(testImage)
        editSession.applyFilter(.sepia, intensity: 0.8)
        
        mockProcessor.shouldFail = true
        
        let exportData = await editSession.exportImage(format: .jpeg)
        
        XCTAssertNil(exportData)
        XCTAssertEqual(editSession.processingState, .failed(ImageProcessingError.exportFailed))
    }
}
