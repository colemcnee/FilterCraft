import SwiftUI
import FilterCraftCore

/// Flip transformation controls with visual feedback
struct FlipControls: View {
    @ObservedObject var editSession: EditSession
    @State private var showingAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Title
            Text("Flip")
                .font(.headline)
                .foregroundColor(.white)
            
            // Visual preview
            flipPreview
            
            // Control buttons
            flipButtons
            
            // Reset button
            if hasFlips {
                resetButton
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - Flip Preview
    
    private var flipPreview: some View {
        ZStack {
            // Background frame
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: 80, height: 60)
            
            // Preview rectangle showing current flip state
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.opacity(0.7))
                .frame(width: 60, height: 40)
                .scaleEffect(
                    x: editSession.effectiveCropRotateState.isFlippedHorizontally ? -1 : 1,
                    y: editSession.effectiveCropRotateState.isFlippedVertically ? -1 : 1
                )
                .overlay(
                    // Orientation indicator
                    VStack(spacing: 2) {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(4)
                    .scaleEffect(
                        x: editSession.effectiveCropRotateState.isFlippedHorizontally ? -1 : 1,
                        y: editSession.effectiveCropRotateState.isFlippedVertically ? -1 : 1
                    )
                )
                .animation(.easeInOut(duration: 0.3), value: editSession.effectiveCropRotateState.isFlippedHorizontally)
                .animation(.easeInOut(duration: 0.3), value: editSession.effectiveCropRotateState.isFlippedVertically)
        }
    }
    
    // MARK: - Flip Buttons
    
    private var flipButtons: some View {
        HStack(spacing: 20) {
            // Horizontal flip
            flipButton(
                icon: "flip.horizontal",
                title: "Horizontal",
                isActive: editSession.effectiveCropRotateState.isFlippedHorizontally,
                action: flipHorizontal
            )
            
            // Vertical flip
            flipButton(
                icon: "flip.vertical",
                title: "Vertical",
                isActive: editSession.effectiveCropRotateState.isFlippedVertically,
                action: flipVertical
            )
        }
    }
    
    private func flipButton(
        icon: String,
        title: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .blue : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isActive ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isActive ? .blue : .white.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(showingAnimation && isActive ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: showingAnimation)
    }
    
    // MARK: - Reset Button
    
    private var resetButton: some View {
        Button(action: resetFlips) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.caption)
                Text("Reset Flips")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.2))
            .foregroundColor(.red)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasFlips: Bool {
        editSession.effectiveCropRotateState.isFlippedHorizontally ||
        editSession.effectiveCropRotateState.isFlippedVertically
    }
    
    // MARK: - Action Methods
    
    private func flipHorizontal() {
        showingAnimation = true
        
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledHorizontalFlip()
        editSession.updateCropRotateState(newState)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingAnimation = false
        }
    }
    
    private func flipVertical() {
        showingAnimation = true
        
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledVerticalFlip()
        editSession.updateCropRotateState(newState)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showingAnimation = false
        }
    }
    
    private func resetFlips() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState
            .withHorizontalFlip(false)
            .withVerticalFlip(false)
        editSession.updateCropRotateState(newState)
    }
}

// MARK: - Compact Flip Controls

struct CompactFlipControls: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        HStack(spacing: 12) {
            // Horizontal flip toggle
            Button(action: flipHorizontal) {
                Image(systemName: "flip.horizontal")
                    .font(.caption)
                    .foregroundColor(
                        editSession.effectiveCropRotateState.isFlippedHorizontally ? .blue : .white
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        Color.black.opacity(0.6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        editSession.effectiveCropRotateState.isFlippedHorizontally ? Color.blue : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .cornerRadius(6)
            }
            
            // Vertical flip toggle
            Button(action: flipVertical) {
                Image(systemName: "flip.vertical")
                    .font(.caption)
                    .foregroundColor(
                        editSession.effectiveCropRotateState.isFlippedVertically ? .blue : .white
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        Color.black.opacity(0.6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        editSession.effectiveCropRotateState.isFlippedVertically ? Color.blue : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    )
                    .cornerRadius(6)
            }
        }
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
}

// MARK: - Flip Animation Helper

struct FlipAnimationView: View {
    let isFlippedHorizontally: Bool
    let isFlippedVertically: Bool
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue.opacity(0.7))
            .frame(width: 50, height: 30)
            .rotation3DEffect(
                .degrees(Double(animationPhase * 180)),
                axis: (x: isFlippedVertically ? 1 : 0, y: isFlippedHorizontally ? 1 : 0, z: 0)
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animationPhase = 1
                }
            }
    }
}

#Preview("FlipControls") {
    FlipControls(editSession: EditSession.preview)
        .frame(width: 250, height: 300)
        .background(Color.black)
}

#Preview("CompactFlipControls") {
    CompactFlipControls(editSession: EditSession.preview)
        .frame(width: 100, height: 50)
        .background(Color.black)
}