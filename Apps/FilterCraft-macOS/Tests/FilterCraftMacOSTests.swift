import XCTest
import SwiftUI
@testable import FilterCraft_macOS

final class FilterCraftMacOSTests: XCTestCase {
    
    func testAppInitialization() throws {
        let app = FilterCraftApp()
        XCTAssertNotNil(app.body)
    }
    
    func testContentViewInitialization() throws {
        let contentView = ContentView()
        XCTAssertNotNil(contentView.body)
    }
    
    func testToolbarViewInitialization() throws {
        let editSession = EditSession()
        let showingBeforeAfter = Binding.constant(false)
        let showingInspector = Binding.constant(true)
        let zoomScale = Binding.constant(1.0)
        
        let toolbarView = ToolbarView(
            editSession: editSession,
            showingBeforeAfter: showingBeforeAfter,
            showingInspector: showingInspector,
            zoomScale: zoomScale,
            onOpenImage: {},
            onSaveImage: {},
            onReset: {}
        )
        
        XCTAssertNotNil(toolbarView.body)
    }
    
    func testInspectorViewWithEmptySession() throws {
        let editSession = EditSession()
        let inspectorView = InspectorView(editSession: editSession)
        
        XCTAssertNotNil(inspectorView.body)
    }
    
    func testDropZoneViewInitialization() throws {
        let dragIsActive = Binding.constant(false)
        let dropZoneView = DropZoneView(
            dragIsActive: dragIsActive,
            onImageDropped: { _ in },
            onOpenClicked: {}
        )
        
        XCTAssertNotNil(dropZoneView.body)
    }
    
    func testFilterButtonInitialization() throws {
        let filterButton = FilterButton(
            filterType: .vintage,
            isSelected: false,
            action: {}
        )
        
        XCTAssertNotNil(filterButton.body)
    }
    
    func testAdjustmentControlsViewInitialization() throws {
        let adjustments = Binding.constant(ImageAdjustments())
        let adjustmentControlsView = AdjustmentControlsView(adjustments: adjustments)
        
        XCTAssertNotNil(adjustmentControlsView.body)
    }
    
    func testFilterCraftCommandsInitialization() throws {
        let commands = FilterCraftCommands()
        XCTAssertNotNil(commands.body)
    }
    
    func testNotificationNames() throws {
        // Test that all notification names are properly defined
        XCTAssertEqual(Notification.Name.openImage.rawValue, "openImage")
        XCTAssertEqual(Notification.Name.saveImage.rawValue, "saveImage")
        XCTAssertEqual(Notification.Name.exportImage.rawValue, "exportImage")
        XCTAssertEqual(Notification.Name.resetEdits.rawValue, "resetEdits")
        XCTAssertEqual(Notification.Name.copyImage.rawValue, "copyImage")
        XCTAssertEqual(Notification.Name.toggleInspector.rawValue, "toggleInspector")
        XCTAssertEqual(Notification.Name.toggleBeforeAfter.rawValue, "toggleBeforeAfter")
        XCTAssertEqual(Notification.Name.zoomIn.rawValue, "zoomIn")
        XCTAssertEqual(Notification.Name.zoomOut.rawValue, "zoomOut")
        XCTAssertEqual(Notification.Name.zoomActualSize.rawValue, "zoomActualSize")
        XCTAssertEqual(Notification.Name.zoomToFit.rawValue, "zoomToFit")
        XCTAssertEqual(Notification.Name.applyFilter.rawValue, "applyFilter")
        XCTAssertEqual(Notification.Name.showHelp.rawValue, "showHelp")
    }
}