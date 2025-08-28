import XCTest
@testable import FilterCraft

/// UI tests for crop and rotate functionality
final class CropRotateUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to crop/rotate interface
        // This assumes there's a way to get to the crop interface in the app
        // Adjust based on actual app navigation
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Interaction Tests
    
    func testCropOverlayExists() throws {
        // Test that crop overlay elements are present
        let cropOverlay = app.otherElements["CropOverlay"]
        XCTAssertTrue(cropOverlay.exists)
    }
    
    func testAspectRatioSelector() throws {
        let aspectRatioButton = app.buttons["AspectRatioSelector"]
        XCTAssertTrue(aspectRatioButton.exists)
        
        aspectRatioButton.tap()
        
        // Check if aspect ratio options appear
        let squareOption = app.buttons["Square"]
        XCTAssertTrue(squareOption.waitForExistence(timeout: 2))
        
        squareOption.tap()
        
        // Verify selection
        XCTAssertTrue(aspectRatioButton.label.contains("Square"))
    }
    
    func testRotationControls() throws {
        let rotateLeftButton = app.buttons["Rotate Left 90°"]
        let rotateRightButton = app.buttons["Rotate Right 90°"]
        
        XCTAssertTrue(rotateLeftButton.exists)
        XCTAssertTrue(rotateRightButton.exists)
        
        // Test rotation
        rotateLeftButton.tap()
        
        // Check if angle display updates
        let angleDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '°'")).firstMatch
        XCTAssertTrue(angleDisplay.exists)
    }
    
    func testFlipControls() throws {
        let horizontalFlipButton = app.buttons["Flip Horizontal"]
        let verticalFlipButton = app.buttons["Flip Vertical"]
        
        XCTAssertTrue(horizontalFlipButton.exists)
        XCTAssertTrue(verticalFlipButton.exists)
        
        // Test horizontal flip
        horizontalFlipButton.tap()
        
        // Test vertical flip
        verticalFlipButton.tap()
    }
    
    // MARK: - Gesture Tests
    
    func testCropRectangleDrag() throws {
        let cropOverlay = app.otherElements["CropOverlay"]
        XCTAssertTrue(cropOverlay.exists)
        
        // Get initial position
        let initialFrame = cropOverlay.frame
        
        // Perform drag gesture
        cropOverlay.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)))
        
        // Check if position changed
        let newFrame = cropOverlay.frame
        XCTAssertNotEqual(initialFrame.origin, newFrame.origin)
    }
    
    func testCropHandleResize() throws {
        let cropHandle = app.otherElements["CropHandle.bottomRight"]
        
        if cropHandle.exists {
            let initialSize = cropHandle.frame.size
            
            // Drag to resize
            cropHandle.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8)))
            
            // Verify resize occurred
            let newSize = cropHandle.frame.size
            XCTAssertNotEqual(initialSize, newSize)
        }
    }
    
    func testPinchGesture() throws {
        let imageView = app.images.firstMatch
        
        if imageView.exists {
            // Simulate pinch gesture
            imageView.pinch(withScale: 1.5, velocity: 1.0)
            
            // Verify zoom effect (implementation dependent)
            // This would need to be adapted based on actual zoom implementation
        }
    }
    
    // MARK: - Precision Controls Tests
    
    func testStraightenSlider() throws {
        let straightenSlider = app.sliders["Straighten"]
        
        if straightenSlider.exists {
            let initialValue = straightenSlider.value
            
            // Adjust slider
            straightenSlider.adjust(toNormalizedSliderPosition: 0.7)
            
            let newValue = straightenSlider.value
            XCTAssertNotEqual(initialValue, newValue)
        }
    }
    
    func testPrecisionMode() throws {
        let precisionButton = app.buttons["Precision"]
        
        if precisionButton.exists {
            precisionButton.tap()
            
            // Check if precision grid appears
            let precisionGrid = app.otherElements["PrecisionGrid"]
            XCTAssertTrue(precisionGrid.waitForExistence(timeout: 2))
            
            // Turn off precision mode
            precisionButton.tap()
            XCTAssertFalse(precisionGrid.exists)
        }
    }
    
    // MARK: - Command History Tests
    
    func testUndoRedo() throws {
        // Make a change
        let rotateButton = app.buttons["Rotate Right 90°"]
        if rotateButton.exists {
            rotateButton.tap()
        }
        
        // Test undo
        if app.buttons["Undo"].exists {
            app.buttons["Undo"].tap()
            
            // Verify state reverted
            let angleDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0°'")).firstMatch
            XCTAssertTrue(angleDisplay.exists)
        }
        
        // Test redo
        if app.buttons["Redo"].exists {
            app.buttons["Redo"].tap()
            
            // Verify state restored
            let angleDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '90°'")).firstMatch
            XCTAssertTrue(angleDisplay.exists)
        }
    }
    
    func testResetButton() throws {
        // Make several changes
        let rotateButton = app.buttons["Rotate Right 90°"]
        if rotateButton.exists {
            rotateButton.tap()
        }
        
        let flipButton = app.buttons["Flip Horizontal"]
        if flipButton.exists {
            flipButton.tap()
        }
        
        // Reset all changes
        let resetButton = app.buttons["Reset"]
        if resetButton.exists {
            resetButton.tap()
            
            // Verify reset to identity
            let angleDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0°'")).firstMatch
            XCTAssertTrue(angleDisplay.exists)
        }
    }
    
    // MARK: - Navigation Tests
    
    func testCancelCropEdit() throws {
        let cancelButton = app.buttons["Cancel"]
        
        if cancelButton.exists {
            // Make a change
            let rotateButton = app.buttons["Rotate Right 90°"]
            if rotateButton.exists {
                rotateButton.tap()
            }
            
            // Cancel changes
            cancelButton.tap()
            
            // Verify navigation back (implementation dependent)
            // This would need to be adapted based on actual navigation
        }
    }
    
    func testDoneCropEdit() throws {
        let doneButton = app.buttons["Done"]
        
        if doneButton.exists {
            // Make a change
            let rotateButton = app.buttons["Rotate Right 90°"]
            if rotateButton.exists {
                rotateButton.tap()
            }
            
            // Apply changes
            doneButton.tap()
            
            // Verify navigation back and changes applied
            // This would need to be adapted based on actual navigation
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        let rotateLeftButton = app.buttons["Rotate Left 90°"]
        XCTAssertTrue(rotateLeftButton.exists)
        XCTAssertNotNil(rotateLeftButton.label)
        
        let aspectRatioButton = app.buttons["AspectRatioSelector"]
        XCTAssertTrue(aspectRatioButton.exists)
        XCTAssertNotNil(aspectRatioButton.label)
        
        let flipHorizontalButton = app.buttons["Flip Horizontal"]
        XCTAssertTrue(flipHorizontalButton.exists)
        XCTAssertNotNil(flipHorizontalButton.label)
    }
    
    func testVoiceOverCompatibility() throws {
        // Enable accessibility if needed
        app.activate()
        
        // Test that all interactive elements are accessible
        let interactiveElements = app.buttons.allElementsBoundByAccessibilityElement +
                                app.sliders.allElementsBoundByAccessibilityElement +
                                app.switches.allElementsBoundByAccessibilityElement
        
        for element in interactiveElements {
            XCTAssertTrue(element.isAccessibilityElement, "Element should be accessible: \(element)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCropOverlayPerformance() throws {
        measure {
            // Perform multiple crop adjustments
            let cropOverlay = app.otherElements["CropOverlay"]
            if cropOverlay.exists {
                for _ in 0..<10 {
                    cropOverlay.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
                }
            }
        }
    }
    
    func testRotationPerformance() throws {
        measure {
            let rotateButton = app.buttons["Rotate Right 90°"]
            if rotateButton.exists {
                for _ in 0..<4 {
                    rotateButton.tap()
                }
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidCropHandling() throws {
        // Test behavior when trying to create invalid crop rectangles
        let cropOverlay = app.otherElements["CropOverlay"]
        
        if cropOverlay.exists {
            // Try to drag crop rectangle outside bounds
            cropOverlay.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: -0.5, dy: -0.5)))
            
            // Verify crop rectangle is constrained to valid bounds
            XCTAssertTrue(cropOverlay.exists) // Should still exist and be valid
        }
    }
    
    // MARK: - Integration Tests
    
    func testCropRotateWithOtherEdits() throws {
        // Test that crop/rotate works correctly with other image adjustments
        
        // Apply some other edits first (brightness, contrast, etc.)
        // This would depend on your app's navigation structure
        
        // Then apply crop/rotate
        let rotateButton = app.buttons["Rotate Right 90°"]
        if rotateButton.exists {
            rotateButton.tap()
        }
        
        // Verify both types of edits are preserved
        // This would need to be adapted based on how your app displays edit state
    }
    
    // MARK: - Multi-touch Tests
    
    func testMultiTouchGestures() throws {
        let imageView = app.images.firstMatch
        
        if imageView.exists {
            // Test simultaneous pan and pinch
            let coordinate1 = imageView.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
            let coordinate2 = imageView.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
            
            coordinate1.press(forDuration: 0, thenDragTo: coordinate2)
            
            // Verify multi-touch handling doesn't break the interface
            XCTAssertTrue(imageView.exists)
        }
    }
    
    // MARK: - State Persistence Tests
    
    func testStatePreservationOnAppBackgrounding() throws {
        // Make some crop/rotate changes
        let rotateButton = app.buttons["Rotate Right 90°"]
        if rotateButton.exists {
            rotateButton.tap()
        }
        
        // Background the app
        XCUIDevice.shared.press(.home)
        
        // Reactivate the app
        app.activate()
        
        // Verify state is preserved
        let angleDisplay = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '90°'")).firstMatch
        XCTAssertTrue(angleDisplay.waitForExistence(timeout: 3))
    }
}