#if os(macOS)
import SwiftUI
import FilterCraftCore

/// macOS-optimized crop overlay with mouse interaction
struct MacCropOverlay: View {
    @ObservedObject var editSession: EditSession
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragType: DragType = .none
    @State private var initialCropRect: CGRect = .zero
    @State private var hoverHandle: CropHandle? = nil
    
    private let handleSize: CGFloat = 8
    private let cornerRadius: CGFloat = 4
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay
                cropMask(geometry: geometry)
                
                // Crop rectangle
                cropRectangle(geometry: geometry)
                
                // Handles
                cropHandles(geometry: geometry)
            }
        }
        .clipped()
        .onHover { hovering in
            if hovering {
                cursorForDragType.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
    
    // MARK: - Crop Mask
    
    private func cropMask(geometry: GeometryProxy) -> some View {
        let cropRect = denormalizedCropRect(geometry: geometry)
        
        return ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.6))
            
            Rectangle()
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
    }
    
    // MARK: - Crop Rectangle
    
    private func cropRectangle(geometry: GeometryProxy) -> some View {
        let cropRect = denormalizedCropRect(geometry: geometry)
        
        return Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: cropRect.width, height: cropRect.height)
            .position(x: cropRect.midX, y: cropRect.midY)
            .onTapGesture(count: 2) {
                // Double-click to reset crop
                resetCrop()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handlePanDrag(value, geometry: geometry)
                    }
                    .onEnded { _ in
                        commitChange()
                    }
            )
    }
    
    // MARK: - Crop Handles
    
    private func cropHandles(geometry: GeometryProxy) -> some View {
        let cropRect = denormalizedCropRect(geometry: geometry)
        
        return ZStack {
            // Corner handles
            ForEach(CropHandle.allCases, id: \.self) { handle in
                cornerHandle(handle, geometry: geometry, cropRect: cropRect)
            }
            
            // Edge handles
            ForEach(CropEdge.allCases, id: \.self) { edge in
                edgeHandle(edge, geometry: geometry, cropRect: cropRect)
            }
        }
    }
    
    private func cornerHandle(_ handle: CropHandle, geometry: GeometryProxy, cropRect: CGRect) -> some View {
        let position = handle.position(in: cropRect)
        let isHovered = hoverHandle == handle
        
        return Rectangle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .cornerRadius(cornerRadius)
            .scaleEffect(isHovered ? 1.2 : 1.0)
            .position(position)
            .onHover { hovering in
                hoverHandle = hovering ? handle : nil
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleCornerDrag(handle, value, geometry: geometry)
                    }
                    .onEnded { _ in
                        commitChange()
                    }
            )
    }
    
    private func edgeHandle(_ edge: CropEdge, geometry: GeometryProxy, cropRect: CGRect) -> some View {
        let (position, size) = edge.positionAndSize(in: cropRect, handleSize: handleSize)
        
        return Rectangle()
            .fill(Color.clear)
            .frame(width: size.width, height: size.height)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleEdgeDrag(edge, value, geometry: geometry)
                    }
                    .onEnded { _ in
                        commitChange()
                    }
            )
    }
    
    // MARK: - Gesture Handlers
    
    private func handlePanDrag(_ value: DragGesture.Value, geometry: GeometryProxy) {
        if !isDragging {
            isDragging = true
            dragType = .move
            initialCropRect = editSession.effectiveCropRotateState.cropRect
        }
        
        let normalizedTranslation = CGSize(
            width: value.translation.width / geometry.size.width,
            height: value.translation.height / geometry.size.height
        )
        
        var newCropRect = initialCropRect
        newCropRect.origin.x += normalizedTranslation.width
        newCropRect.origin.y += normalizedTranslation.height
        
        // Constrain to bounds
        newCropRect.origin.x = max(0, min(1 - newCropRect.width, newCropRect.origin.x))
        newCropRect.origin.y = max(0, min(1 - newCropRect.height, newCropRect.origin.y))
        
        let newState = editSession.effectiveCropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func handleCornerDrag(_ handle: CropHandle, _ value: DragGesture.Value, geometry: GeometryProxy) {
        if !isResizing {
            isResizing = true
            dragType = .resize(handle)
            initialCropRect = editSession.effectiveCropRotateState.cropRect
        }
        
        let normalizedTranslation = CGSize(
            width: value.translation.width / geometry.size.width,
            height: value.translation.height / geometry.size.height
        )
        
        var newCropRect = initialCropRect
        
        switch handle {
        case .topLeft:
            newCropRect.origin.x += normalizedTranslation.width
            newCropRect.origin.y += normalizedTranslation.height
            newCropRect.size.width -= normalizedTranslation.width
            newCropRect.size.height -= normalizedTranslation.height
            
        case .topRight:
            newCropRect.origin.y += normalizedTranslation.height
            newCropRect.size.width += normalizedTranslation.width
            newCropRect.size.height -= normalizedTranslation.height
            
        case .bottomLeft:
            newCropRect.origin.x += normalizedTranslation.width
            newCropRect.size.width -= normalizedTranslation.width
            newCropRect.size.height += normalizedTranslation.height
            
        case .bottomRight:
            newCropRect.size.width += normalizedTranslation.width
            newCropRect.size.height += normalizedTranslation.height
        }
        
        // Apply aspect ratio constraints
        if let aspectRatio = editSession.effectiveCropRotateState.aspectRatio {
            newCropRect = aspectRatio.constrain(rect: newCropRect, in: CGSize(width: 1, height: 1))
        }
        
        newCropRect = validateCropRect(newCropRect)
        
        let newState = editSession.effectiveCropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func handleEdgeDrag(_ edge: CropEdge, _ value: DragGesture.Value, geometry: GeometryProxy) {
        if !isResizing {
            isResizing = true
            dragType = .resize(nil) // Edge resize
            initialCropRect = editSession.effectiveCropRotateState.cropRect
        }
        
        let normalizedTranslation = CGSize(
            width: value.translation.width / geometry.size.width,
            height: value.translation.height / geometry.size.height
        )
        
        var newCropRect = initialCropRect
        
        switch edge {
        case .top:
            newCropRect.origin.y += normalizedTranslation.height
            newCropRect.size.height -= normalizedTranslation.height
        case .bottom:
            newCropRect.size.height += normalizedTranslation.height
        case .left:
            newCropRect.origin.x += normalizedTranslation.width
            newCropRect.size.width -= normalizedTranslation.width
        case .right:
            newCropRect.size.width += normalizedTranslation.width
        }
        
        // Apply aspect ratio constraints
        if let aspectRatio = editSession.effectiveCropRotateState.aspectRatio {
            newCropRect = aspectRatio.constrain(rect: newCropRect, in: CGSize(width: 1, height: 1))
        }
        
        newCropRect = validateCropRect(newCropRect)
        
        let newState = editSession.effectiveCropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func commitChange() {
        isDragging = false
        isResizing = false
        dragType = .none
        initialCropRect = .zero
        editSession.commitTemporaryCropRotateState()
    }
    
    private func resetCrop() {
        let resetState = editSession.effectiveCropRotateState.withCropRect(
            CGRect(x: 0, y: 0, width: 1, height: 1)
        )
        editSession.updateCropRotateState(resetState)
    }
    
    // MARK: - Helper Methods
    
    private func denormalizedCropRect(geometry: GeometryProxy) -> CGRect {
        let normalizedRect = editSession.effectiveCropRotateState.cropRect
        return CGRect(
            x: normalizedRect.minX * geometry.size.width,
            y: normalizedRect.minY * geometry.size.height,
            width: normalizedRect.width * geometry.size.width,
            height: normalizedRect.height * geometry.size.height
        )
    }
    
    private func validateCropRect(_ rect: CGRect) -> CGRect {
        var validRect = rect
        
        // Ensure minimum size
        let minSize: CGFloat = 0.05
        validRect.size.width = max(minSize, validRect.size.width)
        validRect.size.height = max(minSize, validRect.size.height)
        
        // Ensure maximum size
        validRect.size.width = min(1.0, validRect.size.width)
        validRect.size.height = min(1.0, validRect.size.height)
        
        // Ensure rect stays in bounds
        validRect.origin.x = max(0, min(1 - validRect.size.width, validRect.origin.x))
        validRect.origin.y = max(0, min(1 - validRect.size.height, validRect.origin.y))
        
        return validRect
    }
    
    private var cursorForDragType: NSCursor {
        switch dragType {
        case .none:
            return .arrow
        case .move:
            return .openHand
        case .resize(let handle):
            if let handle = handle {
                switch handle {
                case .topLeft, .bottomRight:
                    return .resizeUpLeftDownRight
                case .topRight, .bottomLeft:
                    return .resizeUpRightDownLeft
                }
            } else {
                return .resizeUpDown // Edge resize
            }
        }
    }
}

// MARK: - Supporting Types

private enum DragType: Equatable {
    case none
    case move
    case resize(CropHandle?)
}

// MARK: - Shared Types (from iOS version)

private enum CropHandle: CaseIterable, Equatable {
    case topLeft, topRight, bottomLeft, bottomRight
    
    func position(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: rect.minX, y: rect.minY)
        case .topRight:
            return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft:
            return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight:
            return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }
}

private enum CropEdge: CaseIterable {
    case top, bottom, left, right
    
    func positionAndSize(in rect: CGRect, handleSize: CGFloat) -> (CGPoint, CGSize) {
        switch self {
        case .top:
            return (
                CGPoint(x: rect.midX, y: rect.minY),
                CGSize(width: rect.width - handleSize * 2, height: handleSize)
            )
        case .bottom:
            return (
                CGPoint(x: rect.midX, y: rect.maxY),
                CGSize(width: rect.width - handleSize * 2, height: handleSize)
            )
        case .left:
            return (
                CGPoint(x: rect.minX, y: rect.midY),
                CGSize(width: handleSize, height: rect.height - handleSize * 2)
            )
        case .right:
            return (
                CGPoint(x: rect.maxX, y: rect.midY),
                CGSize(width: handleSize, height: rect.height - handleSize * 2)
            )
        }
    }
}

// MARK: - NSCursor Extensions

extension NSCursor {
    static let resizeUpLeftDownRight = NSCursor.init(image: NSImage(systemSymbolName: "arrow.up.left.and.down.right", accessibilityDescription: nil) ?? NSImage(), hotSpot: NSPoint(x: 8, y: 8))
    static let resizeUpRightDownLeft = NSCursor.init(image: NSImage(systemSymbolName: "arrow.up.right.and.down.left", accessibilityDescription: nil) ?? NSImage(), hotSpot: NSPoint(x: 8, y: 8))
}

#Preview {
    MacCropOverlay(editSession: EditSession.preview)
        .frame(width: 400, height: 300)
        .background(Color.gray)
}

#endif