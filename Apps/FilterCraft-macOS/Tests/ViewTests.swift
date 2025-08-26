import XCTest
import SwiftUI
import CoreImage
@testable import FilterCraft_macOS

final class ViewTests: XCTestCase {
    
    var testImage: CIImage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        testImage = CIImage(color: CIColor.red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    override func tearDownWithError() throws {
        testImage = nil
        try super.tearDownWithError()
    }
    
    func testImageCanvasViewWithSingleImage() throws {
        let zoomScale = Binding.constant(1.0)
        let showingBeforeAfter = Binding.constant(false)
        
        let canvasView = ImageCanvasView(
            image: testImage,
            originalImage: nil,
            zoomScale: zoomScale,
            showingBeforeAfter: showingBeforeAfter
        )
        
        XCTAssertNotNil(canvasView.body)
    }
    
    func testImageCanvasViewWithBeforeAfter() throws {
        let zoomScale = Binding.constant(1.0)
        let showingBeforeAfter = Binding.constant(true)
        
        let canvasView = ImageCanvasView(
            image: testImage,
            originalImage: testImage,
            zoomScale: zoomScale,
            showingBeforeAfter: showingBeforeAfter
        )
        
        XCTAssertNotNil(canvasView.body)
    }
    
    func testImageViewWithValidImage() throws {
        let imageView = ImageView(image: testImage)
        XCTAssertNotNil(imageView.body)
    }
    
    func testAdjustmentSliderInitialization() throws {
        let value = Binding.constant(0.0 as Float)
        
        let slider = AdjustmentSlider(
            title: "Test Slider",
            value: value,
            range: -1...1,
            icon: "sun.max"
        )
        
        XCTAssertNotNil(slider.body)
    }
    
    func testFilterButtonStates() throws {
        // Test unselected state
        let unselectedButton = FilterButton(
            filterType: .vintage,
            isSelected: false,
            action: {}
        )
        XCTAssertNotNil(unselectedButton.body)
        
        // Test selected state
        let selectedButton = FilterButton(
            filterType: .vintage,
            isSelected: true,
            action: {}
        )
        XCTAssertNotNil(selectedButton.body)
    }
    
    func testInfoRowFormatting() throws {
        let infoRow = InfoRow(label: "Test Label", value: "Test Value")
        XCTAssertNotNil(infoRow.body)
    }
    
    func testEditOperationTypeIconNames() throws {
        XCTAssertEqual(EditOperationType.imageLoad.iconName, "photo")
        XCTAssertEqual(EditOperationType.adjustmentChange.iconName, "slider.horizontal.3")
        XCTAssertEqual(EditOperationType.filterApplication.iconName, "camera.filters")
        XCTAssertEqual(EditOperationType.reset.iconName, "arrow.counterclockwise")
    }
    
    func testDropZoneViewStates() throws {
        // Test inactive state
        let dragIsActiveInactive = Binding.constant(false)
        let inactiveDropZone = DropZoneView(
            dragIsActive: dragIsActiveInactive,
            onImageDropped: { _ in },
            onOpenClicked: {}
        )
        XCTAssertNotNil(inactiveDropZone.body)
        
        // Test active state
        let dragIsActiveActive = Binding.constant(true)
        let activeDropZone = DropZoneView(
            dragIsActive: dragIsActiveActive,
            onImageDropped: { _ in },
            onOpenClicked: {}
        )
        XCTAssertNotNil(activeDropZone.body)
    }
    
    func testImagePickerViewInitialization() throws {
        let imagePicker = ImagePickerView { _ in }
        XCTAssertNotNil(imagePicker)
    }
    
    func testImagePickerViewControllerInitialization() throws {
        let controller = ImagePickerViewController()
        XCTAssertNotNil(controller)
        XCTAssertNil(controller.onImageSelected)
    }
    
    func testFilterMenuCommandsInitialization() throws {
        let filterMenuCommands = FilterMenuCommands()
        XCTAssertNotNil(filterMenuCommands.body)
    }
}

// MARK: - Integration Tests

final class IntegrationTests: XCTestCase {
    
    func testFullWorkflowWithEditSession() async throws {
        let editSession = EditSession()
        
        // Test initial state
        XCTAssertEqual(editSession.processingState, .idle)
        XCTAssertNil(editSession.originalImage)
        XCTAssertFalse(editSession.hasEdits)
        
        // Load test image
        let testImage = CIImage(color: CIColor.blue).cropped(to: CGRect(x: 0, y: 0, width: 200, height: 200))
        await editSession.loadImage(testImage)
        
        // Verify image loaded
        XCTAssertEqual(editSession.originalImage, testImage)
        XCTAssertEqual(editSession.processingState, .completed)
        XCTAssertFalse(editSession.hasEdits) // No edits initially
        
        // Apply filter
        editSession.applyFilter(.vintage, intensity: 0.8)
        
        // Verify filter applied
        XCTAssertNotNil(editSession.appliedFilter)
        XCTAssertEqual(editSession.appliedFilter?.filterType, .vintage)
        XCTAssertEqual(editSession.appliedFilter?.intensity, 0.8)
        XCTAssertTrue(editSession.hasEdits)
        
        // Apply adjustments
        let adjustments = ImageAdjustments(brightness: 0.3, contrast: 0.2)
        editSession.updateAdjustments(adjustments)
        
        // Verify adjustments applied
        XCTAssertEqual(editSession.adjustments.brightness, 0.3)
        XCTAssertEqual(editSession.adjustments.contrast, 0.2)
        XCTAssertTrue(editSession.hasEdits)
        
        // Reset edits
        await editSession.resetToOriginal()
        
        // Verify reset
        XCTAssertFalse(editSession.hasEdits)
        XCTAssertFalse(editSession.adjustments.hasAdjustments)
        XCTAssertNil(editSession.appliedFilter)
        XCTAssertEqual(editSession.processingState, .completed)
    }
    
    func testViewsWithEditSession() async throws {
        let editSession = EditSession()
        
        // Load test image
        let testImage = CIImage(color: CIColor.green).cropped(to: CGRect(x: 0, y: 0, width: 150, height: 150))
        await editSession.loadImage(testImage)
        
        // Test InspectorView with loaded image
        let inspectorView = InspectorView(editSession: editSession)
        XCTAssertNotNil(inspectorView.body)
        
        // Apply some edits
        editSession.applyFilter(.sepia, intensity: 0.7)
        editSession.updateAdjustments(ImageAdjustments(brightness: 0.2, saturation: 0.1))
        
        // Test InspectorView with edits
        let inspectorViewWithEdits = InspectorView(editSession: editSession)
        XCTAssertNotNil(inspectorViewWithEdits.body)
        
        // Test AdjustmentControlsView with current adjustments
        let adjustments = Binding.constant(editSession.adjustments)
        let adjustmentControls = AdjustmentControlsView(adjustments: adjustments)
        XCTAssertNotNil(adjustmentControls.body)
        
        // Test ContentView
        let contentView = ContentView()
        XCTAssertNotNil(contentView.body)
    }
}