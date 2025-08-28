import Foundation
import CoreGraphics

/// Defines aspect ratio constraints for crop operations
public enum AspectRatio: String, CaseIterable, Identifiable, Sendable {
    case freeForm = "freeForm"
    case square = "1:1"
    case traditional = "4:3"
    case widescreen = "16:9"
    case portrait = "3:4"
    case tallscreen = "9:16"
    case golden = "1.618:1"
    case custom = "custom"
    
    public var id: String { rawValue }
    
    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .freeForm: return "Free"
        case .square: return "Square"
        case .traditional: return "4:3"
        case .widescreen: return "16:9"
        case .portrait: return "3:4"
        case .tallscreen: return "9:16"
        case .golden: return "Golden"
        case .custom: return "Custom"
        }
    }
    
    /// Aspect ratio value (width/height), nil for free form
    public var ratio: CGFloat? {
        switch self {
        case .freeForm, .custom: return nil
        case .square: return 1.0
        case .traditional: return 4.0/3.0
        case .widescreen: return 16.0/9.0
        case .portrait: return 3.0/4.0
        case .tallscreen: return 9.0/16.0
        case .golden: return 1.618
        }
    }
    
    /// SF Symbol icon name for UI
    public var iconName: String {
        switch self {
        case .freeForm: return "crop"
        case .square: return "square"
        case .traditional: return "rectangle"
        case .widescreen: return "rectangle.landscape"
        case .portrait: return "rectangle.portrait"
        case .tallscreen: return "iphone"
        case .golden: return "rectangle.ratio.3.to.4"
        case .custom: return "ruler"
        }
    }
    
    /// Description for accessibility
    public var accessibilityLabel: String {
        switch self {
        case .freeForm: return "Free form crop - no aspect ratio constraint"
        case .square: return "Square aspect ratio - 1 to 1"
        case .traditional: return "Traditional aspect ratio - 4 to 3"
        case .widescreen: return "Widescreen aspect ratio - 16 to 9"
        case .portrait: return "Portrait aspect ratio - 3 to 4"
        case .tallscreen: return "Tall screen aspect ratio - 9 to 16"
        case .golden: return "Golden ratio aspect ratio - 1.618 to 1"
        case .custom: return "Custom aspect ratio"
        }
    }
}

// MARK: - Aspect Ratio Calculations

public extension AspectRatio {
    
    /// Constrains a rectangle to this aspect ratio
    /// - Parameters:
    ///   - rect: The rectangle to constrain
    ///   - containerSize: The container bounds
    /// - Returns: Constrained rectangle
    func constrain(rect: CGRect, in containerSize: CGSize) -> CGRect {
        guard let targetRatio = ratio else { return rect }
        
        var constrainedRect = rect
        let currentRatio = rect.width / rect.height
        
        if currentRatio > targetRatio {
            // Too wide - reduce width
            let newWidth = rect.height * targetRatio
            let widthDifference = rect.width - newWidth
            constrainedRect.size.width = newWidth
            constrainedRect.origin.x += widthDifference / 2
        } else if currentRatio < targetRatio {
            // Too tall - reduce height
            let newHeight = rect.width / targetRatio
            let heightDifference = rect.height - newHeight
            constrainedRect.size.height = newHeight
            constrainedRect.origin.y += heightDifference / 2
        }
        
        // Ensure the constrained rect stays within bounds
        return ensureRectInBounds(constrainedRect, containerSize: containerSize)
    }
    
    /// Creates a centered rectangle with this aspect ratio
    /// - Parameters:
    ///   - containerSize: Container to fit the rectangle in
    ///   - fillPercent: How much of the container to fill (0.0 to 1.0)
    /// - Returns: Centered rectangle with correct aspect ratio
    func createCenteredRect(in containerSize: CGSize, fillPercent: CGFloat = 0.8) -> CGRect {
        guard let targetRatio = ratio else {
            // For free form, return a centered 80% rectangle
            let size = CGSize(
                width: containerSize.width * fillPercent,
                height: containerSize.height * fillPercent
            )
            return CGRect(
                x: (containerSize.width - size.width) / 2,
                y: (containerSize.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
        }
        
        let containerRatio = containerSize.width / containerSize.height
        var rectSize: CGSize
        
        if containerRatio > targetRatio {
            // Container is wider than target - constrain by height
            rectSize.height = containerSize.height * fillPercent
            rectSize.width = rectSize.height * targetRatio
        } else {
            // Container is taller than target - constrain by width
            rectSize.width = containerSize.width * fillPercent
            rectSize.height = rectSize.width / targetRatio
        }
        
        return CGRect(
            x: (containerSize.width - rectSize.width) / 2,
            y: (containerSize.height - rectSize.height) / 2,
            width: rectSize.width,
            height: rectSize.height
        )
    }
    
    /// Ensures a rectangle stays within the given bounds
    private func ensureRectInBounds(_ rect: CGRect, containerSize: CGSize) -> CGRect {
        var bounded = rect
        
        // Clamp size to container
        bounded.size.width = min(bounded.size.width, containerSize.width)
        bounded.size.height = min(bounded.size.height, containerSize.height)
        
        // Clamp position to container
        bounded.origin.x = max(0, min(bounded.origin.x, containerSize.width - bounded.size.width))
        bounded.origin.y = max(0, min(bounded.origin.y, containerSize.height - bounded.size.height))
        
        return bounded
    }
}