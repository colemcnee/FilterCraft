import XCTest
@testable import FilterCraftCore

final class FilterCraftCoreTests: XCTestCase {
    
    // MARK: - FilterType Tests
    
    func testFilterTypeProperties() {
        let vintageFilter = FilterType.vintage
        
        XCTAssertEqual(vintageFilter.displayName, "Vintage")
        XCTAssertEqual(vintageFilter.iconName, "camera.filters")
        XCTAssertEqual(vintageFilter.category, .artistic)
        XCTAssertEqual(vintageFilter.defaultIntensity, 0.7)
        XCTAssertTrue(vintageFilter.coreImageFilters.contains("CISepiaTone"))
    }
    
    func testFilterTypeCategories() {
        let filtersByCategory = FilterType.filtersByCategory
        
        XCTAssertTrue(filtersByCategory[.basic]?.contains(.none) == true)
        XCTAssertTrue(filtersByCategory[.basic]?.contains(.blackAndWhite) == true)
        XCTAssertTrue(filtersByCategory[.artistic]?.contains(.vintage) == true)
        XCTAssertTrue(filtersByCategory[.mood]?.contains(.dramatic) == true)
    }
    
    func testFilterTypeAllCases() {
        XCTAssertEqual(FilterType.allCases.count, 9)
        XCTAssertTrue(FilterType.allCases.contains(.none))
        XCTAssertTrue(FilterType.allCases.contains(.vintage))
        XCTAssertTrue(FilterType.allCases.contains(.dramatic))
    }
    
    // MARK: - ImageAdjustments Tests
    
    func testImageAdjustmentsInit() {
        let adjustments = ImageAdjustments()
        
        XCTAssertEqual(adjustments.brightness, 0.0)
        XCTAssertEqual(adjustments.contrast, 0.0)
        XCTAssertEqual(adjustments.saturation, 0.0)
        XCTAssertEqual(adjustments.exposure, 0.0)
        XCTAssertFalse(adjustments.hasAdjustments)
    }
    
    func testImageAdjustmentsCustomInit() {
        let adjustments = ImageAdjustments(
            brightness: 0.5,
            contrast: 0.3,
            saturation: -0.2
        )
        
        XCTAssertEqual(adjustments.brightness, 0.5)
        XCTAssertEqual(adjustments.contrast, 0.3)
        XCTAssertEqual(adjustments.saturation, -0.2)
        XCTAssertTrue(adjustments.hasAdjustments)
    }
    
    func testImageAdjustmentsReset() {
        var adjustments = ImageAdjustments(brightness: 0.5, contrast: 0.3)
        XCTAssertTrue(adjustments.hasAdjustments)
        
        adjustments.reset()
        XCTAssertFalse(adjustments.hasAdjustments)
        XCTAssertEqual(adjustments.brightness, 0.0)
        XCTAssertEqual(adjustments.contrast, 0.0)
    }
    
    func testImageAdjustmentsValueMethods() {
        var adjustments = ImageAdjustments()
        
        XCTAssertEqual(adjustments.value(for: .brightness), 0.0)
        
        adjustments.setValue(0.5, for: .brightness)
        XCTAssertEqual(adjustments.brightness, 0.5)
        XCTAssertEqual(adjustments.value(for: .brightness), 0.5)
        
        // Test clamping
        adjustments.setValue(2.0, for: .brightness)
        XCTAssertEqual(adjustments.brightness, 1.0)
        
        adjustments.setValue(-2.0, for: .brightness)
        XCTAssertEqual(adjustments.brightness, -1.0)
    }
    
    // MARK: - AdjustmentType Tests
    
    func testAdjustmentTypeProperties() {
        let brightnessType = AdjustmentType.brightness
        
        XCTAssertEqual(brightnessType.displayName, "Brightness")
        XCTAssertEqual(brightnessType.iconName, "sun.max.fill")
        XCTAssertEqual(brightnessType.minValue, -1.0)
        XCTAssertEqual(brightnessType.maxValue, 1.0)
        XCTAssertEqual(brightnessType.defaultValue, 0.0)
    }
    
    // MARK: - AppliedFilter Tests
    
    func testAppliedFilterInit() {
        let appliedFilter = AppliedFilter(filterType: .vintage)
        
        XCTAssertEqual(appliedFilter.filterType, .vintage)
        XCTAssertEqual(appliedFilter.intensity, FilterType.vintage.defaultIntensity)
        XCTAssertTrue(appliedFilter.isEffective)
    }
    
    func testAppliedFilterWithCustomIntensity() {
        let appliedFilter = AppliedFilter(filterType: .dramatic, intensity: 0.5)
        
        XCTAssertEqual(appliedFilter.intensity, 0.5)
        XCTAssertEqual(appliedFilter.description, "Dramatic (50%)")
    }
    
    func testAppliedFilterWithIntensity() {
        let originalFilter = AppliedFilter(filterType: .cool, intensity: 0.3)
        let modifiedFilter = originalFilter.withIntensity(0.8)
        
        XCTAssertEqual(originalFilter.intensity, 0.3)
        XCTAssertEqual(modifiedFilter.intensity, 0.8)
        XCTAssertEqual(originalFilter.id, modifiedFilter.id) // Same ID
        XCTAssertEqual(originalFilter.filterType, modifiedFilter.filterType)
    }
    
    func testAppliedFilterIsEffective() {
        let noneFilter = AppliedFilter(filterType: .none)
        XCTAssertFalse(noneFilter.isEffective)
        
        let zeroIntensityFilter = AppliedFilter(filterType: .vintage, intensity: 0.0)
        XCTAssertFalse(zeroIntensityFilter.isEffective)
        
        let effectiveFilter = AppliedFilter(filterType: .vintage, intensity: 0.5)
        XCTAssertTrue(effectiveFilter.isEffective)
    }
    
    // MARK: - FilterCraftCore Tests
    
    func testFilterCraftCoreConstants() {
        XCTAssertEqual(FilterCraftCore.version, "1.0.0")
        XCTAssertEqual(FilterCraftCore.availableFilterCount, 9)
        XCTAssertEqual(FilterCraftCore.availableCategories.count, 3)
        XCTAssertEqual(FilterCraftCore.availableAdjustmentTypes.count, 8)
    }
    
    func testFilterCraftCoreConvenienceMethods() {
        let basicFilters = FilterCraftCore.filters(for: .basic)
        XCTAssertTrue(basicFilters.contains(.none))
        XCTAssertTrue(basicFilters.contains(.blackAndWhite))
        
        let defaultAdjustments = FilterCraftCore.defaultAdjustments()
        XCTAssertFalse(defaultAdjustments.hasAdjustments)
        
        let appliedFilter = FilterCraftCore.createAppliedFilter(type: .sepia)
        XCTAssertEqual(appliedFilter.filterType, .sepia)
        XCTAssertEqual(appliedFilter.intensity, FilterType.sepia.defaultIntensity)
    }
    
    // MARK: - Integration Tests
    
    func testFullWorkflow() {
        // Create adjustments
        var adjustments = FilterCraftCore.defaultAdjustments()
        adjustments.setValue(0.2, for: .brightness)
        adjustments.setValue(0.1, for: .contrast)
        
        XCTAssertTrue(adjustments.hasAdjustments)
        
        // Create applied filter
        let appliedFilter = FilterCraftCore.createAppliedFilter(type: .dramatic)
        let customFilter = appliedFilter.withIntensity(0.8)
        
        XCTAssertEqual(customFilter.description, "Dramatic (80%)")
        XCTAssertTrue(customFilter.isEffective)
        
        // Test filter organization
        let filtersByCategory = FilterCraftCore.filtersByCategory
        XCTAssertEqual(filtersByCategory.keys.count, 3)
        
        let moodFilters = FilterCraftCore.filters(for: .mood)
        XCTAssertTrue(moodFilters.contains(.dramatic))
        XCTAssertTrue(moodFilters.contains(.vibrant))
    }
}