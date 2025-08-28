import Foundation
import CoreGraphics

/// Represents the complete crop and rotate state for an image
/// Uses normalized coordinates (0.0 to 1.0) for device independence
public struct CropRotateState: Equatable, Codable, Sendable {
    
    /// Crop rectangle in normalized coordinates (0.0 to 1.0)
    /// (0,0) is top-left, (1,1) is bottom-right
    public let cropRect: CGRect
    
    /// Rotation angle in radians (clockwise positive)
    public let rotationAngle: Float
    
    /// Whether image should be flipped horizontally
    public let isFlippedHorizontally: Bool
    
    /// Whether image should be flipped vertically  
    public let isFlippedVertically: Bool
    
    /// Current aspect ratio constraint (nil = free form)
    public let aspectRatio: AspectRatio?
    
    // MARK: - Initialization
    
    public init(
        cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        rotationAngle: Float = 0,
        isFlippedHorizontally: Bool = false,
        isFlippedVertically: Bool = false,
        aspectRatio: AspectRatio? = nil
    ) {
        self.cropRect = cropRect
        self.rotationAngle = rotationAngle
        self.isFlippedHorizontally = isFlippedHorizontally
        self.isFlippedVertically = isFlippedVertically
        self.aspectRatio = aspectRatio
    }
    
    /// Returns identity state (no crop/rotate applied)
    public static let identity = CropRotateState()
    
    // MARK: - State Queries
    
    /// Check if any transformations are applied
    public var hasTransformations: Bool {
        return cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) ||
               rotationAngle != 0 ||
               isFlippedHorizontally ||
               isFlippedVertically
    }
    
    /// Check if only crop is applied (no rotation or flips)
    public var hasCropOnly: Bool {
        return cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) &&
               rotationAngle == 0 &&
               !isFlippedHorizontally &&
               !isFlippedVertically
    }
    
    /// Check if any rotation or flip transformations are applied
    public var hasGeometricTransformations: Bool {
        return rotationAngle != 0 || isFlippedHorizontally || isFlippedVertically
    }
    
    /// Rotation angle in degrees for display
    public var rotationDegrees: Float {
        return rotationAngle * 180 / .pi
    }
    
    // MARK: - State Mutations
    
    /// Returns a new state with updated crop rectangle
    public func withCropRect(_ newCropRect: CGRect) -> CropRotateState {
        return CropRotateState(
            cropRect: newCropRect,
            rotationAngle: rotationAngle,
            isFlippedHorizontally: isFlippedHorizontally,
            isFlippedVertically: isFlippedVertically,
            aspectRatio: aspectRatio
        )
    }
    
    /// Returns a new state with updated rotation angle
    public func withRotation(_ newAngle: Float) -> CropRotateState {
        return CropRotateState(
            cropRect: cropRect,
            rotationAngle: newAngle,
            isFlippedHorizontally: isFlippedHorizontally,
            isFlippedVertically: isFlippedVertically,
            aspectRatio: aspectRatio
        )
    }
    
    /// Returns a new state with rotation adjusted by delta
    public func withRotationDelta(_ deltaAngle: Float) -> CropRotateState {
        return withRotation(rotationAngle + deltaAngle)
    }
    
    /// Returns a new state with updated horizontal flip
    public func withHorizontalFlip(_ flipped: Bool) -> CropRotateState {
        return CropRotateState(
            cropRect: cropRect,
            rotationAngle: rotationAngle,
            isFlippedHorizontally: flipped,
            isFlippedVertically: isFlippedVertically,
            aspectRatio: aspectRatio
        )
    }
    
    /// Returns a new state with toggled horizontal flip
    public func withToggledHorizontalFlip() -> CropRotateState {
        return withHorizontalFlip(!isFlippedHorizontally)
    }
    
    /// Returns a new state with updated vertical flip
    public func withVerticalFlip(_ flipped: Bool) -> CropRotateState {
        return CropRotateState(
            cropRect: cropRect,
            rotationAngle: rotationAngle,
            isFlippedHorizontally: isFlippedHorizontally,
            isFlippedVertically: flipped,
            aspectRatio: aspectRatio
        )
    }
    
    /// Returns a new state with toggled vertical flip
    public func withToggledVerticalFlip() -> CropRotateState {
        return withVerticalFlip(!isFlippedVertically)
    }
    
    /// Returns a new state with updated aspect ratio constraint
    public func withAspectRatio(_ newAspectRatio: AspectRatio?) -> CropRotateState {
        return CropRotateState(
            cropRect: cropRect,
            rotationAngle: rotationAngle,
            isFlippedHorizontally: isFlippedHorizontally,
            isFlippedVertically: isFlippedVertically,
            aspectRatio: newAspectRatio
        )
    }
    
    // MARK: - Coordinate Transformations
    
    /// Converts normalized crop rectangle to pixel coordinates
    /// - Parameter imageSize: Size of the source image in pixels
    /// - Returns: Crop rectangle in pixel coordinates
    public func pixelCropRect(for imageSize: CGSize) -> CGRect {
        return CGRect(
            x: cropRect.minX * imageSize.width,
            y: cropRect.minY * imageSize.height,
            width: cropRect.width * imageSize.width,
            height: cropRect.height * imageSize.height
        )
    }
    
    /// Creates normalized crop rectangle from pixel coordinates
    /// - Parameters:
    ///   - pixelRect: Rectangle in pixel coordinates
    ///   - imageSize: Size of the source image in pixels
    /// - Returns: New state with normalized crop rectangle
    public static func fromPixelCropRect(_ pixelRect: CGRect, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0 && imageSize.height > 0 else {
            return CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        
        return CGRect(
            x: pixelRect.minX / imageSize.width,
            y: pixelRect.minY / imageSize.height,
            width: pixelRect.width / imageSize.width,
            height: pixelRect.height / imageSize.height
        )
    }
    
    // MARK: - Validation & Normalization
    
    /// Returns a normalized version of this state with valid coordinates
    public func normalized() -> CropRotateState {
        // Normalize crop rectangle to 0-1 bounds
        var normalizedCrop = cropRect
        normalizedCrop.origin.x = max(0, min(1, cropRect.minX))
        normalizedCrop.origin.y = max(0, min(1, cropRect.minY))
        normalizedCrop.size.width = max(0, min(1 - normalizedCrop.minX, cropRect.width))
        normalizedCrop.size.height = max(0, min(1 - normalizedCrop.minY, cropRect.height))
        
        // Normalize rotation angle to -π to π
        var normalizedRotation = rotationAngle
        while normalizedRotation > .pi {
            normalizedRotation -= 2 * .pi
        }
        while normalizedRotation < -.pi {
            normalizedRotation += 2 * .pi
        }
        
        return CropRotateState(
            cropRect: normalizedCrop,
            rotationAngle: normalizedRotation,
            isFlippedHorizontally: isFlippedHorizontally,
            isFlippedVertically: isFlippedVertically,
            aspectRatio: aspectRatio
        )
    }
    
    /// Validates that the state has reasonable values
    public var isValid: Bool {
        return cropRect.minX >= 0 && cropRect.minY >= 0 &&
               cropRect.maxX <= 1 && cropRect.maxY <= 1 &&
               cropRect.width > 0 && cropRect.height > 0 &&
               rotationAngle.isFinite
    }
}

// MARK: - Convenience Extensions

public extension CropRotateState {
    
    /// Human-readable description of the transformations applied
    var transformationDescription: String {
        var components: [String] = []
        
        if cropRect != CGRect(x: 0, y: 0, width: 1, height: 1) {
            let cropPercent = Int(cropRect.width * cropRect.height * 100)
            components.append("Cropped (\(cropPercent)%)")
        }
        
        if rotationAngle != 0 {
            let degrees = Int(rotationDegrees)
            components.append("Rotated \(degrees)°")
        }
        
        if isFlippedHorizontally {
            components.append("Flipped H")
        }
        
        if isFlippedVertically {
            components.append("Flipped V")
        }
        
        if let aspectRatio = aspectRatio, aspectRatio != .freeForm {
            components.append("Ratio: \(aspectRatio.displayName)")
        }
        
        return components.isEmpty ? "No transformations" : components.joined(separator: ", ")
    }
    
    /// Estimated memory footprint for command storage
    var memoryFootprint: Int {
        return MemoryLayout<CropRotateState>.size
    }
}