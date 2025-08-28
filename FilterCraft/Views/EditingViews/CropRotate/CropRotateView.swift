import SwiftUI
import FilterCraftCore

/// Main crop and rotate editing interface
struct CropRotateView: View {
    @ObservedObject var editSession: EditSession
    @State private var showingAspectRatioPicker = false
    @State private var isDragging = false
    @State private var lastScaleValue: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Main image view with crop overlay
            imageView
            
            // Top toolbar
            VStack {
                topToolbar
                Spacer()
                bottomControls
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
        .statusBarHidden()
    }
    
    // MARK: - Image View
    
    private var imageView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                if let previewImage = editSession.previewImage {
                    Image(decorative: previewImage, scale: 1.0)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    // Placeholder while loading
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                
                // Crop overlay
                CropOverlayView(editSession: editSession)
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    handleImageZoom(value)
                }
                .onEnded { value in
                    lastScaleValue = 1.0
                }
        )
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbar: some View {
        HStack {
            // Cancel button
            Button("Cancel") {
                editSession.cancelTemporaryCropRotateState()
                // Navigate back
            }
            .foregroundColor(.white)
            .fontWeight(.medium)
            
            Spacer()
            
            // Reset button
            Button(action: resetCrop) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .disabled(!editSession.effectiveCropRotateState.hasTransformations)
            .opacity(editSession.effectiveCropRotateState.hasTransformations ? 1.0 : 0.5)
            
            Spacer()
            
            // Done button
            Button("Done") {
                editSession.commitTemporaryCropRotateState()
                // Navigate back
            }
            .foregroundColor(.yellow)
            .fontWeight(.bold)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Primary controls row
            HStack(spacing: 20) {
                // Aspect ratio selector
                CompactAspectRatioSelector(editSession: editSession)
                
                Spacer()
                
                // Rotation controls
                rotationControls
                
                Spacer()
                
                // Flip controls
                flipControls
            }
            .padding(.horizontal)
            
            // Secondary controls row
            HStack(spacing: 20) {
                // Fine adjustment controls
                adjustmentControls
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
        .background(
            Color.black.opacity(0.8)
                .ignoresSafeArea(edges: .bottom)
        )
    }
    
    // MARK: - Rotation Controls
    
    private var rotationControls: some View {
        HStack(spacing: 16) {
            // Rotate left 90°
            Button(action: { rotateLeft() }) {
                Image(systemName: "rotate.left")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
            
            // Free rotation indicator/control
            Text("\(Int(editSession.effectiveCropRotateState.rotationDegrees))°")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(minWidth: 30)
            
            // Rotate right 90°
            Button(action: { rotateRight() }) {
                Image(systemName: "rotate.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Flip Controls
    
    private var flipControls: some View {
        HStack(spacing: 16) {
            // Flip horizontal
            Button(action: { flipHorizontal() }) {
                Image(systemName: "flip.horizontal")
                    .font(.title2)
                    .foregroundColor(editSession.effectiveCropRotateState.isFlippedHorizontally ? .blue : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
            
            // Flip vertical
            Button(action: { flipVertical() }) {
                Image(systemName: "flip.vertical")
                    .font(.title2)
                    .foregroundColor(editSession.effectiveCropRotateState.isFlippedVertically ? .blue : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Adjustment Controls
    
    private var adjustmentControls: some View {
        HStack(spacing: 20) {
            // Straighten control
            StraightenControl(editSession: editSession)
            
            Spacer()
            
            // Precision crop toggle
            Button(action: togglePrecisionMode) {
                HStack(spacing: 4) {
                    Image(systemName: "scope")
                        .font(.caption)
                    Text("Precision")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Action Methods
    
    private func handleImageZoom(_ value: CGFloat) {
        // For future implementation - zoom to fit more content
        // This would adjust the crop rectangle size based on zoom
        let scaleDelta = value / lastScaleValue
        lastScaleValue = value
        
        // Could implement zoom-based crop adjustment here
    }
    
    private func resetCrop() {
        let resetState = CropRotateState.identity
        editSession.updateCropRotateState(resetState)
    }
    
    private func rotateLeft() {
        let currentState = editSession.effectiveCropRotateState
        let newAngle = currentState.rotationAngle - (.pi / 2)
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateState(newState)
    }
    
    private func rotateRight() {
        let currentState = editSession.effectiveCropRotateState
        let newAngle = currentState.rotationAngle + (.pi / 2)
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateState(newState)
    }
    
    private func flipHorizontal() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledHorizontalFlip()
        editSession.updateCropRotateState(newState)
    }
    
    private func flipVertical() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledVerticalFlip()
        editSession.updateCropRotateState(newState)
    }
    
    private func togglePrecisionMode() {
        // For future implementation - show/hide precision grid and controls
    }
}

// MARK: - Straighten Control

struct StraightenControl: View {
    @ObservedObject var editSession: EditSession
    @State private var isDragging = false
    @State private var initialAngle: Float = 0
    
    private let maxStraightenAngle: Float = .pi / 6 // 30 degrees
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "level")
                    .font(.caption)
                Text("Straighten")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            
            // Straighten slider
            Slider(
                value: Binding(
                    get: { editSession.effectiveCropRotateState.rotationAngle },
                    set: { newAngle in
                        let clampedAngle = max(-maxStraightenAngle, min(maxStraightenAngle, newAngle))
                        let currentState = editSession.effectiveCropRotateState
                        let newState = currentState.withRotation(clampedAngle)
                        editSession.updateCropRotateStateTemporary(newState)
                    }
                ),
                in: -maxStraightenAngle...maxStraightenAngle
            ) {
                // On editing changed
                if !$0 {
                    editSession.commitTemporaryCropRotateState()
                }
            }
            .frame(width: 120)
            .accentColor(.yellow)
            
            // Angle display
            Text("\(Int(editSession.effectiveCropRotateState.rotationDegrees))°")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    CropRotateView(editSession: EditSession.preview)
}