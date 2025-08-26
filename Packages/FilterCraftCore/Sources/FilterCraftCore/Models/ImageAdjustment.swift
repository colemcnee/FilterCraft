import Foundation

/// Type of image adjustment for UI organization
public enum AdjustmentType: String, CaseIterable, Identifiable {
    case brightness = "brightness"
    case contrast = "contrast"
    case saturation = "saturation"
    case exposure = "exposure"
    case highlights = "highlights"
    case shadows = "shadows"
    case warmth = "warmth"
    case tint = "tint"
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .brightness:
            return "Brightness"
        case .contrast:
            return "Contrast"
        case .saturation:
            return "Saturation"
        case .exposure:
            return "Exposure"
        case .highlights:
            return "Highlights"
        case .shadows:
            return "Shadows"
        case .warmth:
            return "Warmth"
        case .tint:
            return "Tint"
        }
    }
    
    /// SF Symbol icon name for UI
    public var iconName: String {
        switch self {
        case .brightness:
            return "sun.max.fill"
        case .contrast:
            return "circle.lefthalf.filled"
        case .saturation:
            return "paintpalette.fill"
        case .exposure:
            return "camera.aperture"
        case .highlights:
            return "flashlight.on.fill"
        case .shadows:
            return "moon.fill"
        case .warmth:
            return "thermometer.sun.fill"
        case .tint:
            return "eyedropper.halffull"
        }
    }
    
    /// Minimum allowed value for this adjustment
    public var minValue: Float {
        switch self {
        case .brightness, .contrast, .saturation, .exposure:
            return -1.0
        case .highlights, .shadows:
            return -1.0
        case .warmth, .tint:
            return -1.0
        }
    }
    
    /// Maximum allowed value for this adjustment
    public var maxValue: Float {
        switch self {
        case .brightness, .contrast, .saturation, .exposure:
            return 1.0
        case .highlights, .shadows:
            return 1.0
        case .warmth, .tint:
            return 1.0
        }
    }
    
    /// Default value for this adjustment (neutral)
    public var defaultValue: Float {
        return 0.0
    }
}

/// Represents image adjustments that can be applied to photos
public struct ImageAdjustments: Equatable {
    public var brightness: Float
    public var contrast: Float
    public var saturation: Float
    public var exposure: Float
    public var highlights: Float
    public var shadows: Float
    public var warmth: Float
    public var tint: Float
    
    /// Creates default ImageAdjustments with no modifications
    public init() {
        self.brightness = 0.0
        self.contrast = 0.0
        self.saturation = 0.0
        self.exposure = 0.0
        self.highlights = 0.0
        self.shadows = 0.0
        self.warmth = 0.0
        self.tint = 0.0
    }
    
    /// Creates ImageAdjustments with specified values
    public init(
        brightness: Float = 0.0,
        contrast: Float = 0.0,
        saturation: Float = 0.0,
        exposure: Float = 0.0,
        highlights: Float = 0.0,
        shadows: Float = 0.0,
        warmth: Float = 0.0,
        tint: Float = 0.0
    ) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.exposure = exposure
        self.highlights = highlights
        self.shadows = shadows
        self.warmth = warmth
        self.tint = tint
    }
    
    /// Returns true if any adjustments have been made from default values
    public var hasAdjustments: Bool {
        return brightness != 0.0 ||
               contrast != 0.0 ||
               saturation != 0.0 ||
               exposure != 0.0 ||
               highlights != 0.0 ||
               shadows != 0.0 ||
               warmth != 0.0 ||
               tint != 0.0
    }
    
    /// Resets all adjustments to their default values
    public mutating func reset() {
        brightness = 0.0
        contrast = 0.0
        saturation = 0.0
        exposure = 0.0
        highlights = 0.0
        shadows = 0.0
        warmth = 0.0
        tint = 0.0
    }
    
    /// Gets the value for a specific adjustment type
    public func value(for adjustmentType: AdjustmentType) -> Float {
        switch adjustmentType {
        case .brightness:
            return brightness
        case .contrast:
            return contrast
        case .saturation:
            return saturation
        case .exposure:
            return exposure
        case .highlights:
            return highlights
        case .shadows:
            return shadows
        case .warmth:
            return warmth
        case .tint:
            return tint
        }
    }
    
    /// Sets the value for a specific adjustment type
    public mutating func setValue(_ value: Float, for adjustmentType: AdjustmentType) {
        let clampedValue = max(adjustmentType.minValue, min(adjustmentType.maxValue, value))
        
        switch adjustmentType {
        case .brightness:
            brightness = clampedValue
        case .contrast:
            contrast = clampedValue
        case .saturation:
            saturation = clampedValue
        case .exposure:
            exposure = clampedValue
        case .highlights:
            highlights = clampedValue
        case .shadows:
            shadows = clampedValue
        case .warmth:
            warmth = clampedValue
        case .tint:
            tint = clampedValue
        }
    }
}