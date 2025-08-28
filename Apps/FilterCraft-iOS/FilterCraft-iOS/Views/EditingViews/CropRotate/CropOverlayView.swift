import SwiftUI
import FilterCraftCore

/// Interactive crop overlay with gesture handling and real-time preview
struct CropOverlayView: View {
    @ObservedObject var editSession: EditSession
    @State private var isDragging = false
    @State private var isResizing = false
    @State private var dragOffset: CGSize = .zero
    @State private var initialCropRect: CGRect = .zero
    @State private var imageSize: CGSize = .zero
    @State private var overlaySize: CGSize = .zero
    @GestureState private var magnifyBy = 1.0
    @GestureState private var panBy = CGSize.zero
    
    private let cornerRadius: CGFloat = 8
    private let handleSize: CGFloat = 20
    private let gridLineWidth: CGFloat = 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent overlay covering non-cropped areas
                cropMask(geometry: geometry)
                
                // Crop rectangle with handles
                cropRectangle(geometry: geometry)
                
                // Rule of thirds grid
                if isDragging || isResizing {
                    ruleOfThirdsGrid(geometry: geometry)
                }
            }
            .onAppear {
                overlaySize = geometry.size
                updateImageSize()
            }
            .onChange(of: geometry.size) { newSize in
                overlaySize = newSize
            }
            .onChange(of: editSession.previewImage) { _ in
                updateImageSize()
            }
        }
        .clipped()
    }
    
    // MARK: - Crop Mask
    
    private func cropMask(geometry: GeometryProxy) -> some View {
        let cropRect = denormalizedCropRect(geometry: geometry)
        
        return ZStack {
            // Full overlay
            Rectangle()
                .fill(Color.black.opacity(0.5))
            
            // Cut out crop area
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
        
        return ZStack {
            // Main crop rectangle border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropRect.width, height: cropRect.height)
                .position(x: cropRect.midX, y: cropRect.midY)
            
            // Corner handles
            ForEach(CropHandle.allCases, id: \.self) { handle in
                cropHandle(handle, geometry: geometry, cropRect: cropRect)
            }
            
            // Edge handles for resizing
            ForEach(CropEdge.allCases, id: \.self) { edge in
                edgeHandle(edge, geometry: geometry, cropRect: cropRect)
            }
        }
        .gesture(
            panGesture(geometry: geometry)
                .simultaneously(with: resizeGesture(geometry: geometry))
        )
    }
    
    // MARK: - Corner Handles
    
    private func cropHandle(_ handle: CropHandle, geometry: GeometryProxy, cropRect: CGRect) -> some View {
        let position = handle.position(in: cropRect)
        
        return Rectangle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleCornerDrag(handle: handle, translation: value.translation, geometry: geometry)
                    }
                    .onEnded { _ in
                        commitCropChange()
                    }
            )
    }
    
    // MARK: - Edge Handles
    
    private func edgeHandle(_ edge: CropEdge, geometry: GeometryProxy, cropRect: CGRect) -> some View {
        let (position, size) = edge.positionAndSize(in: cropRect, handleSize: handleSize)
        
        return Rectangle()
            .fill(Color.clear)
            .frame(width: size.width, height: size.height)
            .position(position)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleEdgeDrag(edge: edge, translation: value.translation, geometry: geometry)
                    }
                    .onEnded { _ in
                        commitCropChange()
                    }
            )
    }
    
    // MARK: - Rule of Thirds Grid
    
    private func ruleOfThirdsGrid(geometry: GeometryProxy) -> some View {
        let cropRect = denormalizedCropRect(geometry: geometry)
        
        return ZStack {
            // Vertical lines
            ForEach(1..<3) { i in
                let x = cropRect.minX + (cropRect.width * CGFloat(i) / 3)
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: gridLineWidth, height: cropRect.height)
                    .position(x: x, y: cropRect.midY)
            }
            
            // Horizontal lines
            ForEach(1..<3) { i in
                let y = cropRect.minY + (cropRect.height * CGFloat(i) / 3)
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: cropRect.width, height: gridLineWidth)
                    .position(x: cropRect.midX, y: y)
            }
        }
    }
    
    // MARK: - Gesture Handlers
    
    private func panGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if !isResizing {
                    handlePanDrag(translation: value.translation, geometry: geometry)
                }
            }
            .onEnded { _ in
                if !isResizing {
                    commitCropChange()
                }
            }
    }
    
    private func resizeGesture(geometry: GeometryProxy) -> some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                handleMagnificationChange(scale: scale, geometry: geometry)
            }
            .onEnded { _ in
                commitCropChange()
            }
    }
    
    private func handlePanDrag(translation: CGSize, geometry: GeometryProxy) {
        guard !isResizing else { return }
        
        isDragging = true
        let normalizedTranslation = CGSize(
            width: translation.width / geometry.size.width,
            height: translation.height / geometry.size.height
        )
        
        var newCropRect = editSession.effectiveCropRotateState.cropRect
        newCropRect.origin.x += normalizedTranslation.width - dragOffset.width
        newCropRect.origin.y += normalizedTranslation.height - dragOffset.height
        
        // Constrain to bounds
        newCropRect.origin.x = max(0, min(1 - newCropRect.width, newCropRect.origin.x))
        newCropRect.origin.y = max(0, min(1 - newCropRect.height, newCropRect.origin.y))
        
        let newState = editSession.cropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
        
        dragOffset = CGSize(
            width: translation.width / geometry.size.width,
            height: translation.height / geometry.size.height
        )
    }
    
    private func handleCornerDrag(handle: CropHandle, translation: CGSize, geometry: GeometryProxy) {
        isResizing = true
        
        let normalizedTranslation = CGSize(
            width: translation.width / geometry.size.width,
            height: translation.height / geometry.size.height
        )
        
        var newCropRect = initialCropRect.isEmpty ? editSession.effectiveCropRotateState.cropRect : initialCropRect
        
        if initialCropRect.isEmpty {
            initialCropRect = editSession.effectiveCropRotateState.cropRect
        }
        
        // Apply handle-specific transformations
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
        
        // Ensure minimum size and bounds
        newCropRect = validateCropRect(newCropRect)
        
        let newState = editSession.cropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func handleEdgeDrag(edge: CropEdge, translation: CGSize, geometry: GeometryProxy) {
        isResizing = true
        
        let normalizedTranslation = CGSize(
            width: translation.width / geometry.size.width,
            height: translation.height / geometry.size.height
        )
        
        var newCropRect = initialCropRect.isEmpty ? editSession.effectiveCropRotateState.cropRect : initialCropRect
        
        if initialCropRect.isEmpty {
            initialCropRect = editSession.effectiveCropRotateState.cropRect
        }
        
        // Apply edge-specific transformations
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
        
        // Ensure minimum size and bounds
        newCropRect = validateCropRect(newCropRect)
        
        let newState = editSession.cropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func handleMagnificationChange(scale: Double, geometry: GeometryProxy) {
        guard abs(scale - 1.0) > 0.01 else { return }
        
        isResizing = true
        let currentRect = editSession.effectiveCropRotateState.cropRect
        let center = CGPoint(x: currentRect.midX, y: currentRect.midY)
        
        var newSize = CGSize(
            width: currentRect.width * scale,
            height: currentRect.height * scale
        )
        
        // Apply aspect ratio constraints
        if let aspectRatio = editSession.effectiveCropRotateState.aspectRatio,
           let ratio = aspectRatio.ratio {
            let currentRatio = newSize.width / newSize.height
            if currentRatio > ratio {
                newSize.width = newSize.height * ratio
            } else {
                newSize.height = newSize.width / ratio
            }
        }
        
        // Constrain size to reasonable bounds
        let minSize: CGFloat = 0.1
        let maxSize: CGFloat = 1.0
        newSize.width = max(minSize, min(maxSize, newSize.width))
        newSize.height = max(minSize, min(maxSize, newSize.height))
        
        var newCropRect = CGRect(
            x: center.x - newSize.width / 2,
            y: center.y - newSize.height / 2,
            width: newSize.width,
            height: newSize.height
        )
        
        // Ensure rect stays in bounds
        newCropRect = validateCropRect(newCropRect)
        
        let newState = editSession.cropRotateState.withCropRect(newCropRect)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func commitCropChange() {
        isDragging = false
        isResizing = false
        dragOffset = .zero
        initialCropRect = .zero
        
        // Commit the temporary state
        editSession.commitTemporaryCropRotateState()
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
    
    private func updateImageSize() {
        if let image = editSession.previewImage {
            imageSize = image.extent.size
        }
    }
}

// MARK: - Supporting Enums

private enum CropHandle: CaseIterable {
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

#Preview {
    CropOverlayView(editSession: EditSession.preview)
        .frame(width: 300, height: 400)
        .background(Color.gray)
}
