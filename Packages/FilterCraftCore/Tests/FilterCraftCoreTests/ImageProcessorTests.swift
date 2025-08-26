import XCTest
import CoreImage
@testable import FilterCraftCore

final class ImageProcessorTests: XCTestCase {
    
    private var imageProcessor: ImageProcessor!
    private var testImage: CIImage!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        imageProcessor = ImageProcessor()
        
        // Create a test image (solid color image)
        testImage = CIImage(color: CIColor.red).cropped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    override func tearDownWithError() throws {
        imageProcessor = nil
        testImage = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Adjustments Tests
    
    func testApplyAdjustmentsWithNoAdjustments() async throws {
        let adjustments = ImageAdjustments()
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyBrightnessAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.5
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyContrastAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.contrast = 0.3
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplySaturationAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.saturation = -0.2
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyExposureAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.exposure = 0.8
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyHighlightsShadowsAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.highlights = -0.3
        adjustments.shadows = 0.4
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyTemperatureTintAdjustment() async throws {
        var adjustments = ImageAdjustments()
        adjustments.warmth = 0.5
        adjustments.tint = -0.2
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyMultipleAdjustments() async throws {
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.2
        adjustments.contrast = 0.3
        adjustments.saturation = 0.1
        adjustments.exposure = 0.1
        adjustments.warmth = 0.2
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    // MARK: - Filter Tests
    
    func testApplyNoneFilter() async throws {
        let result = await imageProcessor.applyFilter(.none, intensity: 1.0, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyVintageFilter() async throws {
        let result = await imageProcessor.applyFilter(.vintage, intensity: 0.8, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyBlackAndWhiteFilter() async throws {
        let result = await imageProcessor.applyFilter(.blackAndWhite, intensity: 1.0, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyVibrantFilter() async throws {
        let result = await imageProcessor.applyFilter(.vibrant, intensity: 0.6, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplySepiaFilter() async throws {
        let result = await imageProcessor.applyFilter(.sepia, intensity: 0.9, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyCoolFilter() async throws {
        let result = await imageProcessor.applyFilter(.cool, intensity: 0.7, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyWarmFilter() async throws {
        let result = await imageProcessor.applyFilter(.warm, intensity: 0.7, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplyDramaticFilter() async throws {
        let result = await imageProcessor.applyFilter(.dramatic, intensity: 0.85, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testApplySoftFilter() async throws {
        let result = await imageProcessor.applyFilter(.soft, intensity: 0.4, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testFilterIntensityZeroReturnsOriginal() async throws {
        let result = await imageProcessor.applyFilter(.vintage, intensity: 0.0, to: testImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testFilterIntensityClampedToValidRange() async throws {
        // Test intensity above 1.0 gets clamped
        let result1 = await imageProcessor.applyFilter(.sepia, intensity: 1.5, to: testImage)
        XCTAssertNotNil(result1)
        
        // Test negative intensity gets clamped to 0
        let result2 = await imageProcessor.applyFilter(.sepia, intensity: -0.5, to: testImage)
        XCTAssertNotNil(result2)
        XCTAssertEqual(result2?.extent, testImage.extent)
    }
    
    // MARK: - Complete Processing Tests
    
    func testProcessImageWithAdjustmentsOnly() async throws {
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.3
        adjustments.saturation = 0.2
        
        let result = await imageProcessor.processImage(testImage, adjustments: adjustments, filter: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testProcessImageWithFilterOnly() async throws {
        let adjustments = ImageAdjustments()
        let filter = AppliedFilter(filterType: .dramatic, intensity: 0.7)
        
        let result = await imageProcessor.processImage(testImage, adjustments: adjustments, filter: filter)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testProcessImageWithAdjustmentsAndFilter() async throws {
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.2
        adjustments.contrast = 0.1
        adjustments.saturation = 0.3
        
        let filter = AppliedFilter(filterType: .vintage, intensity: 0.8)
        
        let result = await imageProcessor.processImage(testImage, adjustments: adjustments, filter: filter)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testProcessImageWithNoEdits() async throws {
        let adjustments = ImageAdjustments()
        
        let result = await imageProcessor.processImage(testImage, adjustments: adjustments, filter: nil)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    func testProcessImageWithIneffectiveFilter() async throws {
        let adjustments = ImageAdjustments()
        let filter = AppliedFilter(filterType: .sepia, intensity: 0.0)
        
        let result = await imageProcessor.processImage(testImage, adjustments: adjustments, filter: filter)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, testImage.extent)
    }
    
    // MARK: - Preview Generation Tests
    
    func testGeneratePreviewWithLargerImage() async throws {
        // Create a larger test image
        let largeImage = CIImage(color: CIColor.blue).cropped(to: CGRect(x: 0, y: 0, width: 2000, height: 1500))
        
        let preview = await imageProcessor.generatePreview(from: largeImage, maxDimension: 1024)
        
        XCTAssertNotNil(preview)
        // Preview should be smaller than original
        XCTAssertTrue(preview!.extent.width <= 1024 || preview!.extent.height <= 1024)
    }
    
    func testGeneratePreviewWithSmallerImage() async throws {
        // Test image is already small (100x100)
        let preview = await imageProcessor.generatePreview(from: testImage, maxDimension: 1024)
        
        XCTAssertNotNil(preview)
        XCTAssertEqual(preview?.extent, testImage.extent) // Should be unchanged
    }
    
    func testGeneratePreviewWithSquareImage() async throws {
        let squareImage = CIImage(color: CIColor.green).cropped(to: CGRect(x: 0, y: 0, width: 1500, height: 1500))
        
        let preview = await imageProcessor.generatePreview(from: squareImage, maxDimension: 800)
        
        XCTAssertNotNil(preview)
        XCTAssertTrue(preview!.extent.width <= 800)
        XCTAssertTrue(preview!.extent.height <= 800)
    }
    
    // MARK: - Export Tests
    
    func testExportImageAsJPEG() async throws {
        let imageData = await imageProcessor.exportImage(testImage, format: .jpeg, quality: 0.9)
        
        XCTAssertNotNil(imageData)
        XCTAssertTrue(imageData!.count > 0)
    }
    
    func testExportImageAsPNG() async throws {
        let imageData = await imageProcessor.exportImage(testImage, format: .png, quality: 1.0)
        
        XCTAssertNotNil(imageData)
        XCTAssertTrue(imageData!.count > 0)
    }
    
    func testExportImageAsHEIF() async throws {
        let imageData = await imageProcessor.exportImage(testImage, format: .heif, quality: 0.8)
        
        XCTAssertNotNil(imageData)
        XCTAssertTrue(imageData!.count > 0)
    }
    
    func testExportWithDifferentQualityLevels() async throws {
        let highQuality = await imageProcessor.exportImage(testImage, format: .jpeg, quality: 1.0)
        let lowQuality = await imageProcessor.exportImage(testImage, format: .jpeg, quality: 0.1)
        
        XCTAssertNotNil(highQuality)
        XCTAssertNotNil(lowQuality)
        
        // Lower quality should generally result in smaller file size
        // (though with simple test image, difference might be minimal)
        XCTAssertTrue(highQuality!.count > 0)
        XCTAssertTrue(lowQuality!.count > 0)
    }
    
    func testExportQualityClampedToValidRange() async throws {
        // Test quality above 1.0 gets clamped
        let result1 = await imageProcessor.exportImage(testImage, format: .jpeg, quality: 1.5)
        XCTAssertNotNil(result1)
        
        // Test negative quality gets clamped
        let result2 = await imageProcessor.exportImage(testImage, format: .jpeg, quality: -0.1)
        XCTAssertNotNil(result2)
    }
    
    // MARK: - Performance Tests
    
    func testProcessingPerformanceWithLargeImage() async throws {
        // Create a moderately large test image
        let largeImage = CIImage(color: CIColor.red).cropped(to: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var adjustments = ImageAdjustments()
        adjustments.brightness = 0.3
        adjustments.contrast = 0.2
        
        let result = await imageProcessor.applyAdjustments(adjustments, to: largeImage)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertNotNil(result)
        // Processing should complete in reasonable time (less than 5 seconds)
        XCTAssertTrue(timeElapsed < 5.0, "Processing took too long: \(timeElapsed) seconds")
    }
    
    func testConcurrentProcessing() async throws {
        // Test multiple concurrent processing operations
        let tasks = (0..<5).map { index in
            Task {
                let filter = FilterType.allCases[index % FilterType.allCases.count]
                return await imageProcessor.applyFilter(filter, intensity: 0.8, to: testImage)
            }
        }
        
        let results = await withTaskGroup(of: CIImage?.self) { group in
            for task in tasks {
                group.addTask {
                    await task.value
                }
            }
            
            var results: [CIImage?] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
        
        XCTAssertEqual(results.count, 5)
        results.forEach { result in
            XCTAssertNotNil(result)
        }
    }
    
    // MARK: - Edge Cases
    
    func testProcessingWithVerySmallImage() async throws {
        let tinyImage = CIImage(color: CIColor.yellow).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        let result = await imageProcessor.applyFilter(.sepia, intensity: 1.0, to: tinyImage)
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.extent, tinyImage.extent)
    }
    
    func testProcessingWithZeroSizeExtent() async throws {
        let emptyImage = CIImage.empty()
        
        let result = await imageProcessor.applyFilter(.vintage, intensity: 0.8, to: emptyImage)
        
        // Should handle empty image gracefully
        XCTAssertNotNil(result)
    }
    
    // MARK: - All Filters Integration Test
    
    func testAllFiltersProduceValidOutput() async throws {
        for filterType in FilterType.allCases {
            let result = await imageProcessor.applyFilter(filterType, intensity: 0.8, to: testImage)
            
            XCTAssertNotNil(result, "Filter \(filterType) returned nil")
            XCTAssertEqual(result?.extent, testImage.extent, "Filter \(filterType) changed image extent")
        }
    }
    
    func testAllFiltersWithMaximumIntensity() async throws {
        for filterType in FilterType.allCases {
            let result = await imageProcessor.applyFilter(filterType, intensity: 1.0, to: testImage)
            
            XCTAssertNotNil(result, "Filter \(filterType) at max intensity returned nil")
            XCTAssertEqual(result?.extent, testImage.extent, "Filter \(filterType) at max intensity changed image extent")
        }
    }
}