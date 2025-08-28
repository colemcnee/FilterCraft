import XCTest
import CoreImage
import CoreGraphics
@testable import FilterCraftCore

/// Performance tests for crop and rotate functionality
final class CropRotatePerformanceTests: XCTestCase {
    
    var editSession: EditSession!
    var testImages: [CIImage] = []
    
    override func setUp() {
        super.setUp()
        editSession = EditSession()
        
        // Create test images of various sizes
        testImages = [
            createTestImage(size: CGSize(width: 100, height: 100)),    // Small
            createTestImage(size: CGSize(width: 1920, height: 1080)),  // HD
            createTestImage(size: CGSize(width: 4096, height: 2160)),  // 4K
            createTestImage(size: CGSize(width: 8192, height: 4320))   // 8K
        ]
    }
    
    override func tearDown() {
        editSession = nil
        testImages.removeAll()
        super.tearDown()
    }
    
    private func createTestImage(size: CGSize) -> CIImage {
        return CIImage(color: CIColor.red).cropped(to: CGRect(origin: .zero, size: size))
    }
    
    // MARK: - State Creation Performance
    
    func testCropRotateStateCreationPerformance() {
        measure {
            for _ in 0..<10000 {
                let _ = CropRotateState(
                    cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                    rotationAngle: .pi / 4,
                    isFlippedHorizontally: Bool.random(),
                    isFlippedVertically: Bool.random(),
                    aspectRatio: AspectRatio.allCases.randomElement()
                )
            }
        }
    }
    
    func testCropRotateStateMutationPerformance() {
        let baseState = CropRotateState.identity
        
        measure {
            var currentState = baseState
            for i in 0..<1000 {
                let progress = Float(i) / 1000.0
                currentState = currentState
                    .withCropRect(CGRect(x: 0, y: 0, width: CGFloat(progress), height: CGFloat(progress)))
                    .withRotation(progress * .pi)
                    .withHorizontalFlip(i % 2 == 0)
                    .withVerticalFlip(i % 3 == 0)
            }
        }
    }
    
    func testCropRotateStateNormalizationPerformance() {
        // Create states with out-of-bounds values that need normalization
        let unnormalizedStates = (0..<1000).map { i in
            CropRotateState(
                cropRect: CGRect(x: -Double(i), y: -Double(i), width: Double(i) * 2, height: Double(i) * 2),
                rotationAngle: Float(i) * .pi // Multiple rotations
            )
        }
        
        measure {
            for state in unnormalizedStates {
                let _ = state.normalized()
            }
        }
    }
    
    // MARK: - Command Performance
    
    func testCropRotateCommandCreationPerformance() {
        let states = (0..<1000).map { i in
            CropRotateState(rotationAngle: Float(i) * .pi / 500)
        }
        
        measure {
            for i in 0..<999 {
                let _ = CropRotateCommand(previousState: states[i], newState: states[i + 1])
            }
        }
    }
    
    func testCropRotateCommandCoalescingPerformance() {
        let commands = (0..<1000).map { i in
            let state1 = CropRotateState(rotationAngle: Float(i) * .pi / 500)
            let state2 = CropRotateState(rotationAngle: Float(i + 1) * .pi / 500)
            return CropRotateCommand(previousState: state1, newState: state2)
        }
        
        measure {
            for i in 0..<999 {
                let _ = commands[i].coalescing(with: commands[i + 1])
            }
        }
    }
    
    // MARK: - AspectRatio Performance
    
    func testAspectRatioConstraintPerformance() {
        let testRects = (0..<1000).map { i in
            CGRect(
                x: Double.random(in: 0...0.5),
                y: Double.random(in: 0...0.5),
                width: Double.random(in: 0.1...0.5),
                height: Double.random(in: 0.1...0.5)
            )
        }
        
        let containerSize = CGSize(width: 1, height: 1)
        
        measure {
            for rect in testRects {
                for aspectRatio in AspectRatio.allCases.dropFirst() { // Skip freeForm
                    let _ = aspectRatio.constrain(rect: rect, in: containerSize)
                }
            }
        }
    }
    
    func testAspectRatioCenteredRectPerformance() {
        let containerSizes = (0..<100).map { i in
            CGSize(width: 100 + i * 10, height: 100 + i * 8)
        }
        
        measure {
            for size in containerSizes {
                for aspectRatio in AspectRatio.allCases.dropFirst() {
                    let _ = aspectRatio.createCenteredRect(in: size, fillPercent: 0.8)
                }
            }
        }
    }
    
    // MARK: - Coordinate Transformation Performance
    
    func testPixelCoordinateConversionPerformance() {
        let imageSize = CGSize(width: 4096, height: 2160)
        let normalizedRects = (0..<1000).map { _ in
            CGRect(
                x: Double.random(in: 0...0.7),
                y: Double.random(in: 0...0.7),
                width: Double.random(in: 0.1...0.3),
                height: Double.random(in: 0.1...0.3)
            )
        }
        
        measure {
            for rect in normalizedRects {
                let state = CropRotateState(cropRect: rect)
                let pixelRect = state.pixelCropRect(for: imageSize)
                let _ = CropRotateState.fromPixelCropRect(pixelRect, imageSize: imageSize)
            }
        }
    }
    
    // MARK: - Image Processing Performance
    
    func testSmallImageCropRotatePerformance() {
        editSession.loadImage(testImages[0], filename: "small.jpg")
        
        let states = (0..<100).map { i in
            CropRotateState(
                cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                rotationAngle: Float(i) * .pi / 50,
                isFlippedHorizontally: i % 2 == 0
            )
        }
        
        measure {
            for state in states {
                editSession.updateCropRotateState(state)
            }
        }
    }
    
    func testHDImageCropRotatePerformance() {
        editSession.loadImage(testImages[1], filename: "hd.jpg")
        
        let states = (0..<50).map { i in
            CropRotateState(
                cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                rotationAngle: Float(i) * .pi / 25,
                isFlippedHorizontally: i % 2 == 0
            )
        }
        
        measure {
            for state in states {
                editSession.updateCropRotateState(state)
            }
        }
    }
    
    func test4KImageCropRotatePerformance() {
        editSession.loadImage(testImages[2], filename: "4k.jpg")
        
        let states = (0..<20).map { i in
            CropRotateState(
                cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                rotationAngle: Float(i) * .pi / 10,
                isFlippedHorizontally: i % 2 == 0
            )
        }
        
        measure {
            for state in states {
                editSession.updateCropRotateState(state)
            }
        }
    }
    
    func test8KImageCropRotatePerformance() {
        editSession.loadImage(testImages[3], filename: "8k.jpg")
        
        let states = (0..<10).map { i in
            CropRotateState(
                cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                rotationAngle: Float(i) * .pi / 5,
                isFlippedHorizontally: i % 2 == 0
            )
        }
        
        measure {
            for state in states {
                editSession.updateCropRotateState(state)
            }
        }
    }
    
    // MARK: - Memory Usage Performance
    
    func testCommandHistoryMemoryUsage() {
        editSession.enableCommandHistory()
        editSession.loadImage(testImages[1], filename: "test.jpg")
        
        measure {
            // Create many commands to test memory usage
            for i in 0..<1000 {
                let state = CropRotateState(rotationAngle: Float(i) * .pi / 500)
                editSession.updateCropRotateState(state)
            }
        }
    }
    
    func testLargeCommandHistoryPerformance() {
        editSession.enableCommandHistory()
        editSession.loadImage(testImages[0], filename: "test.jpg")
        
        // Build up a large command history
        for i in 0..<500 {
            let state = CropRotateState(rotationAngle: Float(i) * .pi / 250)
            editSession.updateCropRotateState(state)
        }
        
        measure {
            // Test undo/redo performance with large history
            Task {
                for _ in 0..<100 {
                    await editSession.undo()
                    await editSession.redo()
                }
            }
        }
    }
    
    // MARK: - Concurrent Access Performance
    
    func testConcurrentStateUpdates() {
        editSession.loadImage(testImages[0], filename: "test.jpg")
        
        measure {
            let expectation = XCTestExpectation(description: "Concurrent updates")
            expectation.expectedFulfillmentCount = 100
            
            for i in 0..<100 {
                Task {
                    let state = CropRotateState(rotationAngle: Float(i) * .pi / 50)
                    editSession.updateCropRotateState(state)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testConcurrentTemporaryStateUpdates() {
        editSession.loadImage(testImages[0], filename: "test.jpg")
        
        measure {
            let expectation = XCTestExpectation(description: "Concurrent temporary updates")
            expectation.expectedFulfillmentCount = 100
            
            for i in 0..<100 {
                Task {
                    let state = CropRotateState(rotationAngle: Float(i) * .pi / 50)
                    editSession.updateCropRotateStateTemporary(state)
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    // MARK: - Real-time Performance
    
    func testRealTimeGesturePerformance() {
        editSession.loadImage(testImages[1], filename: "test.jpg")
        
        // Simulate rapid gesture updates (60fps)
        let gestureStates = (0..<600).map { i in // 10 seconds at 60fps
            CropRotateState(
                cropRect: CGRect(
                    x: 0.1 + Double(i) * 0.001,
                    y: 0.1 + Double(i) * 0.001,
                    width: 0.8,
                    height: 0.8
                )
            )
        }
        
        measure {
            for state in gestureStates {
                editSession.updateCropRotateStateTemporary(state)
            }
            editSession.commitTemporaryCropRotateState()
        }
    }
    
    func testRealTimeRotationGesturePerformance() {
        editSession.loadImage(testImages[1], filename: "test.jpg")
        
        // Simulate rapid rotation gesture updates
        let rotationStates = (0..<300).map { i in
            CropRotateState(rotationAngle: Float(i) * .pi / 150)
        }
        
        measure {
            for state in rotationStates {
                editSession.updateCropRotateStateTemporary(state)
            }
            editSession.commitTemporaryCropRotateState()
        }
    }
    
    // MARK: - Stress Tests
    
    func testExtremeCropValues() {
        let extremeStates = [
            CropRotateState(cropRect: CGRect(x: 0, y: 0, width: 0.001, height: 0.001)),    // Tiny crop
            CropRotateState(cropRect: CGRect(x: 0.999, y: 0.999, width: 0.001, height: 0.001)), // Edge crop
            CropRotateState(rotationAngle: 1000 * .pi),  // Many rotations
            CropRotateState(rotationAngle: -.pi + 0.0001) // Near boundary
        ]
        
        measure {
            for state in extremeStates {
                let normalized = state.normalized()
                XCTAssertTrue(normalized.isValid)
            }
        }
    }
    
    func testRapidStateChanges() {
        editSession.loadImage(testImages[0], filename: "test.jpg")
        editSession.enableCommandHistory()
        
        measure {
            // Rapidly change between different states
            let states = [
                CropRotateState.identity,
                CropRotateState(rotationAngle: .pi / 2),
                CropRotateState(isFlippedHorizontally: true),
                CropRotateState(cropRect: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)),
                CropRotateState(aspectRatio: .square)
            ]
            
            for _ in 0..<100 {
                for state in states {
                    editSession.updateCropRotateState(state)
                }
            }
        }
    }
    
    // MARK: - Memory Pressure Tests
    
    func testLowMemoryConditions() {
        editSession.loadImage(testImages[2], filename: "4k.jpg") // Large image
        
        measure {
            // Create many commands under memory pressure
            for i in 0..<200 {
                let state = CropRotateState(
                    cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                    rotationAngle: Float(i) * .pi / 100,
                    isFlippedHorizontally: i % 2 == 0,
                    isFlippedVertically: i % 3 == 0,
                    aspectRatio: AspectRatio.allCases.randomElement()
                )
                editSession.updateCropRotateState(state)
            }
        }
    }
}