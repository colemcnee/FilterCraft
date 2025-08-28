import SwiftUI
import FilterCraftCore

/// Advanced rotation control with precision adjustment and visual feedback
struct RotationControl: View {
    @ObservedObject var editSession: EditSession
    @State private var isDragging = false
    @State private var dragStartAngle: Float = 0
    @State private var initialRotation: Float = 0
    @State private var snapToCardinalAngles = true
    
    private let dialRadius: CGFloat = 60
    private let handleRadius: CGFloat = 8
    private let snapThreshold: Float = .pi / 36 // 5 degrees in radians
    private let cardinalAngles: [Float] = [0, .pi/2, .pi, -.pi/2] // 0°, 90°, 180°, 270°
    
    var body: some View {
        VStack(spacing: 16) {
            // Rotation dial
            rotationDial
            
            // Quick rotation buttons
            quickRotationButtons
            
            // Precision controls
            precisionControls
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - Rotation Dial
    
    private var rotationDial: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: dialRadius * 2, height: dialRadius * 2)
            
            // Cardinal angle markers
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: 12)
                    .offset(y: -dialRadius + 6)
                    .rotationEffect(.degrees(Double(index) * 90))
            }
            
            // Minor angle markers (every 15 degrees)
            ForEach(0..<24) { index in
                let angle = Double(index) * 15
                if angle.truncatingRemainder(dividingBy: 90) != 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 6)
                        .offset(y: -dialRadius + 3)
                        .rotationEffect(.degrees(angle))
                }
            }
            
            // Current angle indicator
            rotationHandle
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
            
            // Angle text
            Text("\(Int(editSession.effectiveCropRotateState.rotationDegrees))°")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .offset(y: 25)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    handleDialDrag(value)
                }
                .onEnded { _ in
                    commitRotationChange()
                }
        )
    }
    
    private var rotationHandle: some View {
        Circle()
            .fill(isDragging ? Color.yellow : Color.blue)
            .frame(width: handleRadius * 2, height: handleRadius * 2)
            .offset(y: -dialRadius)
            .rotationEffect(.radians(Double(editSession.effectiveCropRotateState.rotationAngle)))
            .scaleEffect(isDragging ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isDragging)
    }
    
    // MARK: - Quick Rotation Buttons
    
    private var quickRotationButtons: some View {
        HStack(spacing: 20) {
            // Rotate left 90°
            rotationButton(
                icon: "rotate.left",
                title: "90° Left",
                action: { rotateBy(-.pi/2) }
            )
            
            // Rotate left 45°
            rotationButton(
                icon: "rotate.left.fill",
                title: "45° Left",
                action: { rotateBy(-.pi/4) }
            )
            
            // Reset rotation
            rotationButton(
                icon: "arrow.counterclockwise",
                title: "Reset",
                action: { resetRotation() }
            )
            .disabled(editSession.effectiveCropRotateState.rotationAngle == 0)
            
            // Rotate right 45°
            rotationButton(
                icon: "rotate.right.fill",
                title: "45° Right",
                action: { rotateBy(.pi/4) }
            )
            
            // Rotate right 90°
            rotationButton(
                icon: "rotate.right",
                title: "90° Right",
                action: { rotateBy(.pi/2) }
            )
        }
    }
    
    private func rotationButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 50, height: 50)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Precision Controls
    
    private var precisionControls: some View {
        VStack(spacing: 12) {
            // Fine adjustment slider
            VStack(spacing: 4) {
                Text("Fine Adjustment")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    Button("-") {
                        rotateBy(-(.pi/180)) // 1 degree
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                    
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
                    .frame(width: 150)
                    .accentColor(.yellow)
                    
                    Button("+") {
                        rotateBy(.pi/180) // 1 degree
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            // Snap toggle
            Toggle("Snap to Cardinal Angles", isOn: $snapToCardinalAngles)
                .font(.caption)
                .foregroundColor(.white)
                .toggleStyle(SwitchToggleStyle(tint: .blue))
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleDialDrag(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            initialRotation = editSession.effectiveCropRotateState.rotationAngle
            dragStartAngle = angleFromPoint(value.startLocation)
        }
        
        let currentAngle = angleFromPoint(value.location)
        var deltaAngle = currentAngle - dragStartAngle
        
        // Handle angle wrap-around
        if deltaAngle > .pi {
            deltaAngle -= 2 * .pi
        } else if deltaAngle < -.pi {
            deltaAngle += 2 * .pi
        }
        
        var newAngle = initialRotation + deltaAngle
        
        // Apply snapping if enabled
        if snapToCardinalAngles {
            newAngle = snapToNearestCardinalAngle(newAngle)
        }
        
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateStateTemporary(newState)
    }
    
    private func angleFromPoint(_ point: CGPoint) -> Float {
        let center = CGPoint(x: dialRadius, y: dialRadius)
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        return Float(atan2(deltaY, deltaX)) + .pi/2 // Adjust for 0° being at top
    }
    
    private func snapToNearestCardinalAngle(_ angle: Float) -> Float {
        let nearestCardinal = cardinalAngles.min { abs($0 - angle) < abs($1 - angle) }
        
        if let cardinal = nearestCardinal, abs(cardinal - angle) <= snapThreshold {
            return cardinal
        }
        
        return angle
    }
    
    private func commitRotationChange() {
        isDragging = false
        editSession.commitTemporaryCropRotateState()
    }
    
    // MARK: - Action Methods
    
    private func rotateBy(_ deltaAngle: Float) {
        let currentState = editSession.effectiveCropRotateState
        var newAngle = currentState.rotationAngle + deltaAngle
        
        // Normalize angle to -π to π
        while newAngle > .pi {
            newAngle -= 2 * .pi
        }
        while newAngle < -.pi {
            newAngle += 2 * .pi
        }
        
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateState(newState)
    }
    
    private func resetRotation() {
        let currentState = editSession.effectiveCropRotateState
        let newState = currentState.withRotation(0)
        editSession.updateCropRotateState(newState)
    }
}

// MARK: - Compact Rotation Control

struct CompactRotationControl: View {
    @ObservedObject var editSession: EditSession
    @State private var showingFullControl = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Current angle display
            Button(action: { showingFullControl = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "dial.max")
                        .font(.caption)
                    Text("\(Int(editSession.effectiveCropRotateState.rotationDegrees))°")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            
            // Quick 90° rotation buttons
            Button(action: { rotateLeft90() }) {
                Image(systemName: "rotate.left")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
            }
            
            Button(action: { rotateRight90() }) {
                Image(systemName: "rotate.right")
                    .font(.caption)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
            }
        }
        .sheet(isPresented: $showingFullControl) {
            NavigationView {
                RotationControl(editSession: editSession)
                    .navigationTitle("Rotation")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { showingFullControl = false }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }
    
    private func rotateLeft90() {
        let currentState = editSession.effectiveCropRotateState
        let newAngle = currentState.rotationAngle - (.pi / 2)
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateState(newState)
    }
    
    private func rotateRight90() {
        let currentState = editSession.effectiveCropRotateState
        let newAngle = currentState.rotationAngle + (.pi / 2)
        let newState = currentState.withRotation(newAngle)
        editSession.updateCropRotateState(newState)
    }
}

#Preview("RotationControl") {
    RotationControl(editSession: EditSession.preview)
        .frame(width: 300, height: 400)
        .background(Color.black)
}

#Preview("CompactRotationControl") {
    CompactRotationControl(editSession: EditSession.preview)
        .frame(width: 200, height: 50)
        .background(Color.black)
}