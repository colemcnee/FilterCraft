import XCTest
import CoreImage
import CoreGraphics
@testable import FilterCraftCore

/// Comprehensive tests for crop and rotate functionality
final class CropRotateTests: XCTestCase {
    
    var editSession: EditSession!
    var testImage: CIImage!
    
    override func setUp() {
        super.setUp()
        editSession = EditSession()
        
        // Create a test image
        testImage = CIImage(color: CIColor.red)
            .cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        
        editSession.loadImage(testImage, filename: "test.jpg")
    }
    
    override func tearDown() {
        editSession = nil
        testImage = nil
        super.tearDown()
    }
    
    // MARK: - CropRotateState Tests
    
    func testCropRotateStateIdentity() {
        let identity = CropRotateState.identity
        
        XCTAssertEqual(identity.cropRect, CGRect(x: 0, y: 0, width: 1, height: 1))
        XCTAssertEqual(identity.rotationAngle, 0)
        XCTAssertFalse(identity.isFlippedHorizontally)
        XCTAssertFalse(identity.isFlippedVertically)
        XCTAssertNil(identity.aspectRatio)
        XCTAssertFalse(identity.hasTransformations)
    }
    
    func testCropRotateStateTransformations() {
        let state = CropRotateState(
            cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
            rotationAngle: .pi / 4,
            isFlippedHorizontally: true,
            isFlippedVertically: false,
            aspectRatio: .square
        )
        
        XCTAssertTrue(state.hasTransformations)
        XCTAssertTrue(state.hasGeometricTransformations)
        XCTAssertFalse(state.hasCropOnly)
        XCTAssertEqual(state.rotationDegrees, 45, accuracy: 0.1)
    }
    
    func testCropRotateStateMutations() {
        let original = CropRotateState.identity
        
        let withCrop = original.withCropRect(CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        XCTAssertEqual(withCrop.cropRect.width, 0.6, accuracy: 0.001)
        
        let withRotation = withCrop.withRotation(.pi / 2)
        XCTAssertEqual(withRotation.rotationAngle, .pi / 2, accuracy: 0.001)
        
        let withFlip = withRotation.withToggledHorizontalFlip()
        XCTAssertTrue(withFlip.isFlippedHorizontally)
        
        let withAspectRatio = withFlip.withAspectRatio(.square)
        XCTAssertEqual(withAspectRatio.aspectRatio, .square)
    }
    
    func testCropRotateStateNormalization() {
        // Test with out-of-bounds values
        let invalidState = CropRotateState(
            cropRect: CGRect(x: -0.5, y: -0.5, width: 2.0, height: 2.0),
            rotationAngle: 10 * .pi // Multiple rotations
        )
        
        let normalized = invalidState.normalized()
        
        XCTAssertGreaterThanOrEqual(normalized.cropRect.minX, 0)
        XCTAssertGreaterThanOrEqual(normalized.cropRect.minY, 0)
        XCTAssertLessThanOrEqual(normalized.cropRect.maxX, 1)
        XCTAssertLessThanOrEqual(normalized.cropRect.maxY, 1)
        XCTAssertLessThanOrEqual(abs(normalized.rotationAngle), .pi)
    }
    
    func testCropRotateStateValidation() {
        let validState = CropRotateState(
            cropRect: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
            rotationAngle: .pi / 4
        )
        XCTAssertTrue(validState.isValid)
        
        let invalidState = CropRotateState(
            cropRect: CGRect(x: -1, y: -1, width: 3, height: 3),
            rotationAngle: .infinity
        )
        XCTAssertFalse(invalidState.isValid)
    }
    
    // MARK: - AspectRatio Tests
    
    func testAspectRatioValues() {
        XCTAssertNil(AspectRatio.freeForm.ratio)
        XCTAssertEqual(AspectRatio.square.ratio, 1.0)
        XCTAssertEqual(AspectRatio.traditional.ratio, 4.0/3.0, accuracy: 0.001)
        XCTAssertEqual(AspectRatio.widescreen.ratio, 16.0/9.0, accuracy: 0.001)
    }
    
    func testAspectRatioConstraints() {
        let originalRect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.6)
        let containerSize = CGSize(width: 1, height: 1)
        
        let squareConstrained = AspectRatio.square.constrain(rect: originalRect, in: containerSize)
        let squareRatio = squareConstrained.width / squareConstrained.height
        XCTAssertEqual(squareRatio, 1.0, accuracy: 0.01)
        
        let widescreenConstrained = AspectRatio.widescreen.constrain(rect: originalRect, in: containerSize)
        let widescreenRatio = widescreenConstrained.width / widescreenConstrained.height
        XCTAssertEqual(widescreenRatio, 16.0/9.0, accuracy: 0.01)
    }
    
    func testAspectRatioCenteredRect() {
        let containerSize = CGSize(width: 100, height: 100)
        
        let squareRect = AspectRatio.square.createCenteredRect(in: containerSize, fillPercent: 0.8)
        XCTAssertEqual(squareRect.width, squareRect.height)
        XCTAssertEqual(squareRect.width, 80, accuracy: 0.1)
        
        let widescreenRect = AspectRatio.widescreen.createCenteredRect(in: containerSize, fillPercent: 0.8)
        let ratio = widescreenRect.width / widescreenRect.height
        XCTAssertEqual(ratio, 16.0/9.0, accuracy: 0.01)
    }
    
    // MARK: - CropRotateCommand Tests
    
    func testCropRotateCommandCreation() {
        let previousState = CropRotateState.identity
        let newState = CropRotateState(cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
        
        let command = CropRotateCommand(previousState: previousState, newState: newState)
        
        XCTAssertNotNil(command.id)
        XCTAssertTrue(command.isValidChange)
        XCTAssertTrue(command.hasValidStates)
        XCTAssertEqual(command.description, "Crop")
    }
    
    func testCropRotateCommandDescription() {
        let identity = CropRotateState.identity
        
        // Test crop command
        let cropState = identity.withCropRect(CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        let cropCommand = CropRotateCommand(previousState: identity, newState: cropState)
        XCTAssertEqual(cropCommand.description, "Crop")
        
        // Test rotation command
        let rotateState = identity.withRotation(.pi / 2)
        let rotateCommand = CropRotateCommand(previousState: identity, newState: rotateState)
        XCTAssertTrue(rotateCommand.description.contains("Rotate +90°"))
        
        // Test flip command
        let flipState = identity.withToggledHorizontalFlip()
        let flipCommand = CropRotateCommand(previousState: identity, newState: flipState)
        XCTAssertEqual(flipCommand.description, "Flip Horizontal")
        
        // Test reset command
        let resetCommand = CropRotateCommand(resettingFromState: cropState)
        XCTAssertEqual(resetCommand.description, "Reset Crop & Rotate")
    }
    
    func testCropRotateCommandCoalescing() {
        let state1 = CropRotateState.identity
        let state2 = state1.withRotation(.pi / 4)
        let state3 = state2.withRotation(.pi / 2)
        
        let command1 = CropRotateCommand(previousState: state1, newState: state2)
        let command2 = CropRotateCommand(previousState: state2, newState: state3)
        
        XCTAssertTrue(command1.canCoalesce(with: command2))
        
        let coalescedCommand = command1.coalescing(with: command2)
        XCTAssertNotNil(coalescedCommand)
        XCTAssertEqual(coalescedCommand?.newState.rotationAngle, .pi / 2, accuracy: 0.001)
    }
    
    // MARK: - EditSession Integration Tests
    
    func testEditSessionCropRotateState() {
        XCTAssertEqual(editSession.cropRotateState, CropRotateState.identity)
        XCTAssertFalse(editSession.hasEdits)
        
        let newState = CropRotateState(cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
        editSession.updateCropRotateState(newState)
        
        XCTAssertEqual(editSession.cropRotateState, newState)
        XCTAssertTrue(editSession.hasEdits)
    }
    
    func testEditSessionTemporaryCropRotateState() {
        let originalState = editSession.cropRotateState
        let tempState = CropRotateState(rotationAngle: .pi / 4)
        
        editSession.updateCropRotateStateTemporary(tempState)
        XCTAssertEqual(editSession.effectiveCropRotateState, tempState)
        XCTAssertEqual(editSession.cropRotateState, originalState) // Original unchanged
        
        editSession.commitTemporaryCropRotateState()
        XCTAssertEqual(editSession.cropRotateState, tempState)
        XCTAssertEqual(editSession.effectiveCropRotateState, tempState)
    }
    
    func testEditSessionCancelTemporaryCropRotateState() {
        let originalState = editSession.cropRotateState
        let tempState = CropRotateState(rotationAngle: .pi / 4)
        
        editSession.updateCropRotateStateTemporary(tempState)
        XCTAssertEqual(editSession.effectiveCropRotateState, tempState)
        
        editSession.cancelTemporaryCropRotateState()
        XCTAssertEqual(editSession.effectiveCropRotateState, originalState)
        XCTAssertEqual(editSession.cropRotateState, originalState)
    }
    
    // MARK: - Command Execution Tests
    
    func testCropRotateCommandExecution() async {
        editSession.enableCommandHistory()
        
        let originalState = editSession.cropRotateState
        let newState = CropRotateState(cropRect: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6))
        
        editSession.updateCropRotateState(newState)
        
        // Wait for command execution
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        XCTAssertEqual(editSession.cropRotateState, newState)
        XCTAssertTrue(editSession.canUndo)
        
        // Test undo
        await editSession.undo()
        XCTAssertEqual(editSession.cropRotateState, originalState)
        XCTAssertTrue(editSession.canRedo)
        
        // Test redo
        await editSession.redo()
        XCTAssertEqual(editSession.cropRotateState, newState)
    }
    
    // MARK: - Coordinate Transformation Tests
    
    func testPixelCropRectConversion() {
        let imageSize = CGSize(width: 1000, height: 800)
        let normalizedRect = CGRect(x: 0.1, y: 0.2, width: 0.6, height: 0.4)
        
        let state = CropRotateState(cropRect: normalizedRect)
        let pixelRect = state.pixelCropRect(for: imageSize)
        
        XCTAssertEqual(pixelRect.minX, 100, accuracy: 0.1)
        XCTAssertEqual(pixelRect.minY, 160, accuracy: 0.1)
        XCTAssertEqual(pixelRect.width, 600, accuracy: 0.1)
        XCTAssertEqual(pixelRect.height, 320, accuracy: 0.1)
        
        // Test reverse conversion
        let backToNormalized = CropRotateState.fromPixelCropRect(pixelRect, imageSize: imageSize)
        XCTAssertEqual(backToNormalized.minX, 0.1, accuracy: 0.001)
        XCTAssertEqual(backToNormalized.minY, 0.2, accuracy: 0.001)
        XCTAssertEqual(backToNormalized.width, 0.6, accuracy: 0.001)
        XCTAssertEqual(backToNormalized.height, 0.4, accuracy: 0.001)
    }
    
    // MARK: - Performance Tests
    
    func testCropRotateStateCreationPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = CropRotateState(
                    cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                    rotationAngle: .pi / 4,
                    isFlippedHorizontally: true,
                    isFlippedVertically: false,
                    aspectRatio: .square
                )
            }
        }
    }
    
    func testCropRotateCommandPerformance() {
        let states = (0..<100).map { i in
            CropRotateState(rotationAngle: Float(i) * .pi / 50)
        }
        
        measure {
            for i in 0..<99 {
                let _ = CropRotateCommand(previousState: states[i], newState: states[i + 1])
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testCropRotateCommandMemoryFootprint() {
        let command = CropRotateCommand(
            previousState: CropRotateState.identity,
            newState: CropRotateState(rotationAngle: .pi / 4)
        )
        
        let expectedSize = MemoryLayout<CropRotateState>.size * 2 +
                          MemoryLayout<UUID>.size +
                          MemoryLayout<Date>.size
        
        XCTAssertEqual(command.memoryFootprint, expectedSize)
    }
    
    // MARK: - Edge Cases
    
    func testZeroSizeCropRect() {
        let zeroState = CropRotateState(cropRect: CGRect(x: 0.5, y: 0.5, width: 0, height: 0))
        XCTAssertFalse(zeroState.isValid)
        
        let normalized = zeroState.normalized()
        XCTAssertGreaterThan(normalized.cropRect.width, 0)
        XCTAssertGreaterThan(normalized.cropRect.height, 0)
    }
    
    func testExtremeRotationAngles() {
        let extremeState = CropRotateState(rotationAngle: 100 * .pi)
        let normalized = extremeState.normalized()
        XCTAssertLessThanOrEqual(abs(normalized.rotationAngle), .pi)
    }
    
    func testConcurrentCropRotateUpdates() async {
        editSession.enableCommandHistory()
        
        let expectation = XCTestExpectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 10
        
        // Simulate concurrent updates
        for i in 0..<10 {
            Task {
                let state = CropRotateState(rotationAngle: Float(i) * .pi / 10)
                editSession.updateCropRotateState(state)
                expectation.fulfill()
            }
        }
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // Verify final state is valid
        XCTAssertTrue(editSession.cropRotateState.isValid)
    }
}