@preconcurrency import CoreImage
import Foundation

/// Protocol defining image processing capabilities
public protocol ImageProcessing {
    /// Apply image adjustments to a CIImage
    func applyAdjustments(_ adjustments: ImageAdjustments, to image: CIImage) async -> CIImage?
    
    /// Apply a filter to a CIImage with specified intensity
    func applyFilter(_ filterType: FilterType, intensity: Float, to image: CIImage) async -> CIImage?
    
    /// Apply both adjustments and filter in the optimal order
    func processImage(_ image: CIImage, adjustments: ImageAdjustments, filter: AppliedFilter?) async -> CIImage?
    
    /// Generate a preview version of an image (scaled down for performance)
    func generatePreview(from image: CIImage, maxDimension: CGFloat) async -> CIImage?
    
    /// Export processed image to Data in specified format
    func exportImage(_ image: CIImage, format: ImageExportFormat, quality: Float) async -> Data?
}

/// Supported image export formats
public enum ImageExportFormat: String, CaseIterable, Sendable {
    case jpeg = "jpeg"
    case png = "png"
    case heif = "heif"
    
    public var displayName: String {
        switch self {
        case .jpeg: return "JPEG"
        case .png: return "PNG"
        case .heif: return "HEIF"
        }
    }
    
    public var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .png: return "png"
        case .heif: return "heic"
        }
    }
}

/// Core Image processing implementation
public class ImageProcessor: ImageProcessing, @unchecked Sendable {
    private let context: CIContext
    private let processingQueue = DispatchQueue(label: "com.filtercraft.image-processing", qos: .userInitiated)
    
    public init() {
        // Configure CIContext with optimal settings for image processing
        let options: [CIContextOption: Any] = [
            .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpaceCreateDeviceRGB(),
            .cacheIntermediates: false
        ]
        self.context = CIContext(options: options)
    }
    
    // MARK: - Public Processing Methods
    
    public func applyAdjustments(_ adjustments: ImageAdjustments, to image: CIImage) async -> CIImage? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = self.processAdjustments(adjustments, image: image)
                continuation.resume(returning: result)
            }
        }
    }
    
    public func applyFilter(_ filterType: FilterType, intensity: Float, to image: CIImage) async -> CIImage? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = self.processFilter(filterType, intensity: intensity, image: image)
                continuation.resume(returning: result)
            }
        }
    }
    
    public func processImage(_ image: CIImage, adjustments: ImageAdjustments, filter: AppliedFilter?) async -> CIImage? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                var processedImage = image
                
                // Apply adjustments first for better visual results
                if adjustments.hasAdjustments {
                    processedImage = self.processAdjustments(adjustments, image: processedImage) ?? processedImage
                }
                
                // Apply filter if specified
                if let filter = filter, filter.isEffective {
                    processedImage = self.processFilter(filter.filterType, intensity: filter.intensity, image: processedImage) ?? processedImage
                }
                
                continuation.resume(returning: processedImage)
            }
        }
    }
    
    public func generatePreview(from image: CIImage, maxDimension: CGFloat = 1024) async -> CIImage? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = self.scaleImageForPreview(image, maxDimension: maxDimension)
                continuation.resume(returning: result)
            }
        }
    }
    
    public func exportImage(_ image: CIImage, format: ImageExportFormat, quality: Float = 0.9) async -> Data? {
        return await withCheckedContinuation { continuation in
            processingQueue.async {
                let result = self.renderImageToData(image, format: format, quality: quality)
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Private Processing Implementation
    
    private func processAdjustments(_ adjustments: ImageAdjustments, image: CIImage) -> CIImage? {
        guard adjustments.hasAdjustments else { return image }
        
        var processedImage = image
        
        // Apply exposure adjustment
        if adjustments.exposure != 0 {
            if let exposureFilter = CIFilter(name: "CIExposureAdjust") {
                exposureFilter.setValue(processedImage, forKey: kCIInputImageKey)
                exposureFilter.setValue(adjustments.exposure, forKey: kCIInputEVKey)
                processedImage = exposureFilter.outputImage ?? processedImage
            }
        }
        
        // Apply highlights and shadows
        if adjustments.highlights != 0 || adjustments.shadows != 0 {
            if let highlightShadowFilter = CIFilter(name: "CIHighlightShadowAdjust") {
                highlightShadowFilter.setValue(processedImage, forKey: kCIInputImageKey)
                highlightShadowFilter.setValue(1.0 + adjustments.highlights, forKey: "inputHighlightAmount")
                highlightShadowFilter.setValue(1.0 + adjustments.shadows, forKey: "inputShadowAmount")
                processedImage = highlightShadowFilter.outputImage ?? processedImage
            }
        }
        
        // Apply temperature and tint
        if adjustments.warmth != 0 || adjustments.tint != 0 {
            if let temperatureFilter = CIFilter(name: "CITemperatureAndTint") {
                temperatureFilter.setValue(processedImage, forKey: kCIInputImageKey)
                // Convert warmth (-1 to 1) to temperature (2000 to 50000)
                let temperature = 6500 + (CGFloat(adjustments.warmth) * 2000)
                let tintedTemp = 6500 + (CGFloat(adjustments.tint) * 1000)
                temperatureFilter.setValue(CIVector(x: temperature, y: 0), forKey: "inputNeutral")
                temperatureFilter.setValue(CIVector(x: tintedTemp, y: 0), forKey: "inputTargetNeutral")
                processedImage = temperatureFilter.outputImage ?? processedImage
            }
        }
        
        // Apply color controls (brightness, contrast, saturation)
        if adjustments.brightness != 0 || adjustments.contrast != 0 || adjustments.saturation != 0 {
            if let colorFilter = CIFilter(name: "CIColorControls") {
                colorFilter.setValue(processedImage, forKey: kCIInputImageKey)
                colorFilter.setValue(adjustments.brightness, forKey: kCIInputBrightnessKey)
                colorFilter.setValue(1.0 + adjustments.contrast, forKey: kCIInputContrastKey)
                colorFilter.setValue(1.0 + adjustments.saturation, forKey: kCIInputSaturationKey)
                processedImage = colorFilter.outputImage ?? processedImage
            }
        }
        
        return processedImage
    }
    
    private func processFilter(_ filterType: FilterType, intensity: Float, image: CIImage) -> CIImage? {
        guard filterType != .none && intensity > 0 else { return image }
        
        let clampedIntensity = max(0.0, min(1.0, intensity))
        
        switch filterType {
        case .none:
            return image
        case .vintage:
            return applyVintageFilter(to: image, intensity: clampedIntensity)
        case .blackAndWhite:
            return applyBlackAndWhiteFilter(to: image, intensity: clampedIntensity)
        case .vibrant:
            return applyVibrantFilter(to: image, intensity: clampedIntensity)
        case .sepia:
            return applySepiaFilter(to: image, intensity: clampedIntensity)
        case .cool:
            return applyCoolFilter(to: image, intensity: clampedIntensity)
        case .warm:
            return applyWarmFilter(to: image, intensity: clampedIntensity)
        case .dramatic:
            return applyDramaticFilter(to: image, intensity: clampedIntensity)
        case .soft:
            return applySoftFilter(to: image, intensity: clampedIntensity)
        }
    }
    
    // MARK: - Filter Implementations
    
    private func applyVintageFilter(to image: CIImage, intensity: Float) -> CIImage? {
        var processedImage = image
        
        // Apply sepia tone
        if let sepiaFilter = CIFilter(name: "CISepiaTone") {
            sepiaFilter.setValue(processedImage, forKey: kCIInputImageKey)
            sepiaFilter.setValue(intensity * 0.8, forKey: kCIInputIntensityKey)
            processedImage = sepiaFilter.outputImage ?? processedImage
        }
        
        // Add vignette effect
        if let vignetteFilter = CIFilter(name: "CIVignette") {
            vignetteFilter.setValue(processedImage, forKey: kCIInputImageKey)
            vignetteFilter.setValue(intensity * 1.5, forKey: kCIInputIntensityKey)
            vignetteFilter.setValue(intensity * 0.5, forKey: kCIInputRadiusKey)
            processedImage = vignetteFilter.outputImage ?? processedImage
        }
        
        return blendWithOriginal(original: image, processed: processedImage, intensity: intensity)
    }
    
    private func applyBlackAndWhiteFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let monoFilter = CIFilter(name: "CIColorMonochrome") else { return image }
        
        monoFilter.setValue(image, forKey: kCIInputImageKey)
        monoFilter.setValue(CIColor.white, forKey: kCIInputColorKey)
        monoFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let processedImage = monoFilter.outputImage else { return image }
        return blendWithOriginal(original: image, processed: processedImage, intensity: intensity)
    }
    
    private func applyVibrantFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let vibranceFilter = CIFilter(name: "CIVibrance") else { return image }
        
        vibranceFilter.setValue(image, forKey: kCIInputImageKey)
        vibranceFilter.setValue(intensity, forKey: "inputAmount")
        
        guard let processedImage = vibranceFilter.outputImage else { return image }
        return processedImage
    }
    
    private func applySepiaFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let sepiaFilter = CIFilter(name: "CISepiaTone") else { return image }
        
        sepiaFilter.setValue(image, forKey: kCIInputImageKey)
        sepiaFilter.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let processedImage = sepiaFilter.outputImage else { return image }
        return blendWithOriginal(original: image, processed: processedImage, intensity: intensity)
    }
    
    private func applyCoolFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let temperatureFilter = CIFilter(name: "CITemperatureAndTint") else { return image }
        
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)
        let temperature = 6500 - (CGFloat(intensity) * 1500) // Cooler temperature
        temperatureFilter.setValue(CIVector(x: temperature, y: 0), forKey: "inputNeutral")
        temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        
        return temperatureFilter.outputImage
    }
    
    private func applyWarmFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let temperatureFilter = CIFilter(name: "CITemperatureAndTint") else { return image }
        
        temperatureFilter.setValue(image, forKey: kCIInputImageKey)
        let temperature = 6500 + (CGFloat(intensity) * 1500) // Warmer temperature
        temperatureFilter.setValue(CIVector(x: temperature, y: 0), forKey: "inputNeutral")
        temperatureFilter.setValue(CIVector(x: 6500, y: 0), forKey: "inputTargetNeutral")
        
        return temperatureFilter.outputImage
    }
    
    private func applyDramaticFilter(to image: CIImage, intensity: Float) -> CIImage? {
        var processedImage = image
        
        // Increase contrast
        if let contrastFilter = CIFilter(name: "CIColorControls") {
            contrastFilter.setValue(processedImage, forKey: kCIInputImageKey)
            contrastFilter.setValue(1.0 + (intensity * 0.4), forKey: kCIInputContrastKey)
            contrastFilter.setValue(1.0 + (intensity * 0.2), forKey: kCIInputSaturationKey)
            processedImage = contrastFilter.outputImage ?? processedImage
        }
        
        // Add vibrance
        if let vibranceFilter = CIFilter(name: "CIVibrance") {
            vibranceFilter.setValue(processedImage, forKey: kCIInputImageKey)
            vibranceFilter.setValue(intensity * 0.5, forKey: "inputAmount")
            processedImage = vibranceFilter.outputImage ?? processedImage
        }
        
        // Subtle vignette
        if let vignetteFilter = CIFilter(name: "CIVignette") {
            vignetteFilter.setValue(processedImage, forKey: kCIInputImageKey)
            vignetteFilter.setValue(intensity * 0.3, forKey: kCIInputIntensityKey)
            processedImage = vignetteFilter.outputImage ?? processedImage
        }
        
        return processedImage
    }
    
    private func applySoftFilter(to image: CIImage, intensity: Float) -> CIImage? {
        guard let blurFilter = CIFilter(name: "CIGaussianBlur") else { return image }
        
        blurFilter.setValue(image, forKey: kCIInputImageKey)
        blurFilter.setValue(intensity * 2.0, forKey: kCIInputRadiusKey)
        
        guard let blurredImage = blurFilter.outputImage else { return image }
        
        // Blend with original for subtle effect
        return blendWithOriginal(original: image, processed: blurredImage, intensity: intensity * 0.6)
    }
    
    // MARK: - Helper Methods
    
    private func blendWithOriginal(original: CIImage, processed: CIImage, intensity: Float) -> CIImage? {
        guard let blendFilter = CIFilter(name: "CISourceOverCompositing") else { return processed }
        
        // Create a mask for blending
        if let multiplyFilter = CIFilter(name: "CIMultiplyCompositing") {
            // Create alpha mask based on intensity
            let alpha = CIImage(color: CIColor(red: CGFloat(intensity), green: CGFloat(intensity), blue: CGFloat(intensity), alpha: 1.0))
                .cropped(to: original.extent)
            
            multiplyFilter.setValue(processed, forKey: kCIInputImageKey)
            multiplyFilter.setValue(alpha, forKey: kCIInputBackgroundImageKey)
            
            if let maskedProcessed = multiplyFilter.outputImage {
                blendFilter.setValue(maskedProcessed, forKey: kCIInputImageKey)
                blendFilter.setValue(original, forKey: kCIInputBackgroundImageKey)
                return blendFilter.outputImage
            }
        }
        
        // Fallback: simple linear blend
        return processed
    }
    
    private func scaleImageForPreview(_ image: CIImage, maxDimension: CGFloat) -> CIImage? {
        let extent = image.extent
        let scale = min(maxDimension / extent.width, maxDimension / extent.height)
        
        if scale >= 1.0 { return image } // No scaling needed
        
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        return image.transformed(by: transform)
    }
    
    private func renderImageToData(_ image: CIImage, format: ImageExportFormat, quality: Float) -> Data? {
        let _ = max(0.0, min(1.0, quality)) // Quality parameter for future use
        
        switch format {
        case .jpeg:
            return context.jpegRepresentation(of: image, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
        case .png:
            return context.pngRepresentation(of: image, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
        case .heif:
            return context.heifRepresentation(of: image, format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
        }
    }
}

// MARK: - Mock Implementation for Testing

/// Mock image processor for testing and development
public class MockImageProcessor: ImageProcessing {
    public var processingDelay: TimeInterval = 0.1
    public var shouldFail: Bool = false
    public var failureError: Error = ImageProcessingError.processingFailed
    
    public init() {}
    
    public func applyAdjustments(_ adjustments: ImageAdjustments, to image: CIImage) async -> CIImage? {
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        return shouldFail ? nil : image
    }
    
    public func applyFilter(_ filterType: FilterType, intensity: Float, to image: CIImage) async -> CIImage? {
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        return shouldFail ? nil : image
    }
    
    public func processImage(_ image: CIImage, adjustments: ImageAdjustments, filter: AppliedFilter?) async -> CIImage? {
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        return shouldFail ? nil : image
    }
    
    public func generatePreview(from image: CIImage, maxDimension: CGFloat) async -> CIImage? {
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        return shouldFail ? nil : image
    }
    
    public func exportImage(_ image: CIImage, format: ImageExportFormat, quality: Float) async -> Data? {
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        return shouldFail ? nil : Data("mock image data".utf8)
    }
}

/// Image processing errors
public enum ImageProcessingError: Error, LocalizedError {
    case processingFailed
    case invalidImage
    case exportFailed
    case unsupportedFormat
    
    public var errorDescription: String? {
        switch self {
        case .processingFailed:
            return "Image processing failed"
        case .invalidImage:
            return "Invalid image provided"
        case .exportFailed:
            return "Failed to export image"
        case .unsupportedFormat:
            return "Unsupported image format"
        }
    }
}