#if os(macOS)
import SwiftUI
import FilterCraftCore

// MARK: - Mac Rotation Controls

struct MacRotationControls: View {
    @ObservedObject var editSession: EditSession
    @State private var angleInput: String = "0"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rotation")
                .font(.headline)
            
            // Current angle display
            HStack {
                Text("Current Angle:")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(editSession.effectiveCropRotateState.rotationDegrees))°")
                    .fontWeight(.medium)
            }
            
            // Rotation slider
            VStack(alignment: .leading, spacing: 4) {
                Text("Adjust Rotation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Slider(
                    value: Binding(
                        get: { editSession.effectiveCropRotateState.rotationAngle },
                        set: { angle in
                            let currentState = editSession.effectiveCropRotateState
                            let newState = currentState.withRotation(angle)
                            editSession.updateCropRotateStateTemporary(newState)
                        }
                    ),
                    in: -.pi...(.pi)
                ) { editing in
                    if !editing {
                        editSession.commitTemporaryCropRotateState()
                    }
                }
            }
            
            // Precise angle input
            HStack {
                Text("Precise Angle:")
                TextField("0", text: $angleInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 60)
                    .onSubmit {
                        applyPreciseAngle()
                    }
                Text("°")
                    .foregroundColor(.secondary)
            }
            
            // Quick rotation buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                rotationButton("90° Left", angle: -.pi/2)
                rotationButton("90° Right", angle: .pi/2)
                rotationButton("180°", angle: .pi)
                rotationButton("Reset", angle: 0)
            }
        }
        .onAppear {
            updateAngleInput()
        }
        .onChange(of: editSession.effectiveCropRotateState.rotationAngle) { _ in
            updateAngleInput()
        }
    }
    
    private func rotationButton(_ title: String, angle: Float) -> some View {
        Button(action: {
            if angle == 0 {
                // Reset
                let currentState = editSession.effectiveCropRotateState
                let newState = currentState.withRotation(0)
                editSession.updateCropRotateState(newState)
            } else {
                // Add to current angle
                let currentState = editSession.effectiveCropRotateState
                var newAngle = currentState.rotationAngle + angle
                
                // Normalize angle
                while newAngle > .pi { newAngle -= 2 * .pi }
                while newAngle < -.pi { newAngle += 2 * .pi }
                
                let newState = currentState.withRotation(newAngle)
                editSession.updateCropRotateState(newState)
            }
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func updateAngleInput() {
        angleInput = String(Int(editSession.effectiveCropRotateState.rotationDegrees))
    }
    
    private func applyPreciseAngle() {
        if let degrees = Int(angleInput) {
            let radians = Float(degrees) * .pi / 180
            let currentState = editSession.effectiveCropRotateState
            let newState = currentState.withRotation(radians)
            editSession.updateCropRotateState(newState)
        }
    }
}

// MARK: - Mac Flip Controls

struct MacFlipControls: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flip")
                .font(.headline)
            
            // Current flip state
            HStack {
                Text("Current State:")
                    .foregroundColor(.secondary)
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flipStatusText)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Flip controls
            VStack(spacing: 8) {
                flipToggle("Horizontal Flip", 
                          isFlipped: editSession.effectiveCropRotateState.isFlippedHorizontally,
                          action: toggleHorizontalFlip)
                
                flipToggle("Vertical Flip", 
                          isFlipped: editSession.effectiveCropRotateState.isFlippedVertically,
                          action: toggleVerticalFlip)
            }
            
            // Reset button
            if hasFlips {
                Button("Reset Flips") {
                    resetFlips()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private func flipToggle(_ title: String, isFlipped: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Toggle(title, isOn: Binding(
                get: { isFlipped },
                set: { _ in action() }
            ))
            .toggleStyle(CheckboxToggleStyle())
            
            Spacer()
            
            Button(action: action) {
                Image(systemName: title.contains("Horizontal") ? "flip.horizontal" : "flip.vertical")
                    .foregroundColor(isFlipped ? .accentColor : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var flipStatusText: String {
        let h = editSession.effectiveCropRotateState.isFlippedHorizontally
        let v = editSession.effectiveCropRotateState.isFlippedVertically
        
        if h && v {
            return "Both"
        } else if h {
            return "Horizontal"
        } else if v {
            return "Vertical"
        } else {
            return "None"
        }
    }
    
    private var hasFlips: Bool {
        editSession.effectiveCropRotateState.isFlippedHorizontally ||
        editSession.effectiveCropRotateState.isFlippedVertically
    }
    
    private func toggleHorizontalFlip() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledHorizontalFlip()
        editSession.updateCropRotateState(newState)
    }
    
    private func toggleVerticalFlip() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withToggledVerticalFlip()
        editSession.updateCropRotateState(newState)
    }
    
    private func resetFlips() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState
            .withHorizontalFlip(false)
            .withVerticalFlip(false)
        editSession.updateCropRotateState(newState)
    }
}

// MARK: - Mac Aspect Ratio Controls

struct MacAspectRatioControls: View {
    @ObservedObject var editSession: EditSession
    @State private var customWidth: String = "16"
    @State private var customHeight: String = "9"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aspect Ratio")
                .font(.headline)
            
            // Current aspect ratio
            HStack {
                Text("Current:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(currentRatioText)
                    .fontWeight(.medium)
            }
            
            // Aspect ratio picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Preset Ratios")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(AspectRatio.allCases.prefix(8), id: \.self) { ratio in
                        aspectRatioButton(ratio)
                    }
                }
            }
            
            // Custom aspect ratio
            if editSession.effectiveCropRotateState.aspectRatio == .custom {
                customAspectRatioControls
            }
            
            // Remove aspect ratio
            if editSession.effectiveCropRotateState.aspectRatio != nil {
                Button("Remove Constraint") {
                    removeAspectRatio()
                }
                .foregroundColor(.red)
            }
        }
    }
    
    private func aspectRatioButton(_ ratio: AspectRatio) -> some View {
        let isSelected = (editSession.effectiveCropRotateState.aspectRatio ?? .freeForm) == ratio
        
        return Button(action: {
            selectAspectRatio(ratio)
        }) {
            Text(ratio.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                .foregroundColor(isSelected ? .white : .accentColor)
                .cornerRadius(4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var customAspectRatioControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Ratio")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Width", text: $customWidth)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                
                Text(":")
                
                TextField("Height", text: $customHeight)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 50)
                
                Button("Apply") {
                    applyCustomRatio()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
    
    private var currentRatioText: String {
        guard let aspectRatio = editSession.effectiveCropRotateState.aspectRatio else {
            return "Free Form"
        }
        
        if aspectRatio == .custom {
            return "Custom"
        } else {
            return aspectRatio.displayName
        }
    }
    
    private func selectAspectRatio(_ ratio: AspectRatio) {
        let currentState = editSession.effectiveCropRotateState
        let newRatio = (ratio == .freeForm) ? nil : ratio
        
        var newCropRect = currentState.cropRect
        
        if let newRatio = newRatio, newRatio != .custom {
            newCropRect = newRatio.constrain(rect: newCropRect, in: CGSize(width: 1, height: 1))
        }
        
        let newState = currentState
            .withAspectRatio(newRatio)
            .withCropRect(newCropRect)
        
        editSession.updateCropRotateState(newState)
    }
    
    private func removeAspectRatio() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withAspectRatio(nil)
        editSession.updateCropRotateState(newState)
    }
    
    private func applyCustomRatio() {
        guard let width = Float(customWidth),
              let height = Float(customHeight),
              width > 0, height > 0 else { return }
        
        let customRatio = CGFloat(width / height)
        let currentState = editSession.effectiveCropRotateState
        
        // Create a custom aspect ratio (for now, use existing enum)
        // In a real implementation, you might extend AspectRatio to support truly custom ratios
        let newCropRect = constrainRectToRatio(currentState.cropRect, ratio: customRatio)
        let newState = currentState
            .withAspectRatio(.custom)
            .withCropRect(newCropRect)
        
        editSession.updateCropRotateState(newState)
    }
    
    private func constrainRectToRatio(_ rect: CGRect, ratio: CGFloat) -> CGRect {
        let currentRatio = rect.width / rect.height
        var constrainedRect = rect
        
        if currentRatio > ratio {
            // Too wide - reduce width
            let newWidth = rect.height * ratio
            let widthDifference = rect.width - newWidth
            constrainedRect.size.width = newWidth
            constrainedRect.origin.x += widthDifference / 2
        } else if currentRatio < ratio {
            // Too tall - reduce height
            let newHeight = rect.width / ratio
            let heightDifference = rect.height - newHeight
            constrainedRect.size.height = newHeight
            constrainedRect.origin.y += heightDifference / 2
        }
        
        // Ensure the constrained rect stays within bounds
        constrainedRect.origin.x = max(0, min(1 - constrainedRect.width, constrainedRect.origin.x))
        constrainedRect.origin.y = max(0, min(1 - constrainedRect.height, constrainedRect.origin.y))
        
        return constrainedRect
    }
}

#Preview("MacRotationControls") {
    MacRotationControls(editSession: EditSession.preview)
        .frame(width: 250)
        .padding()
}

#Preview("MacFlipControls") {
    MacFlipControls(editSession: EditSession.preview)
        .frame(width: 250)
        .padding()
}

#Preview("MacAspectRatioControls") {
    MacAspectRatioControls(editSession: EditSession.preview)
        .frame(width: 250)
        .padding()
}

#endif