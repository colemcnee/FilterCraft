#if os(macOS)
import SwiftUI
import FilterCraftCore

/// macOS-specific crop and rotate interface with precision controls
@available(macOS 12.0, *)
struct MacCropRotateView: View {
    @ObservedObject var editSession: EditSession
    @State private var selectedTool: CropTool = .crop
    @State private var showingInspector = true
    @State private var precisionMode = false
    
    var body: some View {
        HSplitView {
            // Main canvas
            canvasView
                .frame(minWidth: 400)
            
            // Inspector panel
            if showingInspector {
                inspectorPanel
                    .frame(width: 280)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                toolbarControls
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Canvas View
    
    private var canvasView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Image with crop overlay
                imageCanvas(geometry: geometry)
                
                // Tool overlays
                if precisionMode {
                    precisionGrid
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spaceBarPressed)) { _ in
            togglePrecisionMode()
        }
    }
    
    private func imageCanvas(geometry: GeometryProxy) -> some View {
        ZStack {
            // Preview image
            if let previewImage = editSession.previewImage {
                // Convert CIImage to NSImage for display
                if let cgImage = previewImage.cgImage {
                    let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            }
            
            // Crop overlay (reuse iOS component with macOS adaptations)
            MacCropOverlay(editSession: editSession)
        }
    }
    
    // MARK: - Precision Grid
    
    private var precisionGrid: some View {
        ZStack {
            // Rule of thirds
            ForEach(1..<3) { i in
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(height: 1)
                    .offset(y: CGFloat(i - 1) * 100)
                
                Rectangle()
                    .fill(Color.yellow.opacity(0.3))
                    .frame(width: 1)
                    .offset(x: CGFloat(i - 1) * 100)
            }
            
            // Center cross
            Rectangle()
                .fill(Color.red.opacity(0.4))
                .frame(height: 1)
            
            Rectangle()
                .fill(Color.red.opacity(0.4))
                .frame(width: 1)
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Inspector Panel
    
    private var inspectorPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Tool selector
            toolSelector
            
            Divider()
            
            // Current tool controls
            currentToolControls
            
            Divider()
            
            // Precision controls
            precisionControls
            
            Divider()
            
            // Transform summary
            transformSummary
            
            Spacer()
            
            // Action buttons
            actionButtons
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Tool Selector
    
    private var toolSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tools")
                .font(.headline)
            
            Picker("Tool", selection: $selectedTool) {
                ForEach(CropTool.allCases, id: \.self) { tool in
                    Label(tool.displayName, systemImage: tool.iconName)
                        .tag(tool)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Tool Controls
    
    private var currentToolControls: some View {
        Group {
            switch selectedTool {
            case .crop:
                cropControls
            case .rotate:
                MacRotationControls(editSession: editSession)
            case .flip:
                MacFlipControls(editSession: editSession)
            case .aspectRatio:
                MacAspectRatioControls(editSession: editSession)
            }
        }
    }
    
    private var cropControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crop")
                .font(.headline)
            
            // Crop rectangle coordinates
            cropCoordinateControls
            
            // Crop presets
            cropPresets
        }
    }
    
    private var cropCoordinateControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Position & Size")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                coordinateField("X:", value: editSession.effectiveCropRotateState.cropRect.minX) { newX in
                    updateCropRect(x: newX)
                }
                
                coordinateField("Y:", value: editSession.effectiveCropRotateState.cropRect.minY) { newY in
                    updateCropRect(y: newY)
                }
            }
            
            HStack {
                coordinateField("W:", value: editSession.effectiveCropRotateState.cropRect.width) { newW in
                    updateCropRect(width: newW)
                }
                
                coordinateField("H:", value: editSession.effectiveCropRotateState.cropRect.height) { newH in
                    updateCropRect(height: newH)
                }
            }
        }
    }
    
    private func coordinateField(
        _ label: String,
        value: CGFloat,
        onChange: @escaping (CGFloat) -> Void
    ) -> some View {
        HStack {
            Text(label)
                .frame(width: 20, alignment: .leading)
            
            TextField(
                "",
                value: Binding(
                    get: { value * 100 }, // Show as percentage
                    set: { onChange($0 / 100) }
                ),
                format: .number.precision(.fractionLength(1))
            )
            .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("%")
                .foregroundColor(.secondary)
        }
    }
    
    private var cropPresets: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                presetButton("Full Image") { resetCrop() }
                presetButton("Center 80%") { applyCenterCrop(0.8) }
                presetButton("Center 60%") { applyCenterCrop(0.6) }
                presetButton("Center 40%") { applyCenterCrop(0.4) }
            }
        }
    }
    
    private func presetButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
    
    // MARK: - Precision Controls
    
    private var precisionControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Precision")
                .font(.headline)
            
            Toggle("Precision Mode (Space)", isOn: $precisionMode)
            
            Toggle("Snap to Grid", isOn: .constant(false))
            
            HStack {
                Text("Zoom:")
                Slider(value: .constant(1.0), in: 0.1...3.0)
                Text("100%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Transform Summary
    
    private var transformSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Transform")
                .font(.headline)
            
            Text(editSession.effectiveCropRotateState.transformationDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button("Reset All") {
                resetAllTransforms()
            }
            .disabled(!editSession.effectiveCropRotateState.hasTransformations)
            
            HStack {
                Button("Cancel") {
                    editSession.cancelTemporaryCropRotateState()
                }
                .keyboardShortcut(.escape)
                
                Button("Apply") {
                    editSession.commitTemporaryCropRotateState()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Toolbar Controls
    
    private var toolbarControls: some View {
        Group {
            Button(action: { showingInspector.toggle() }) {
                Image(systemName: "sidebar.right")
            }
            .help("Toggle Inspector")
            
            Divider()
            
            Button(action: togglePrecisionMode) {
                Image(systemName: "scope")
            }
            .help("Precision Mode (Space)")
            
            Button(action: resetAllTransforms) {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("Reset All")
            .disabled(!editSession.effectiveCropRotateState.hasTransformations)
        }
    }
    
    // MARK: - Action Methods
    
    private func updateCropRect(x: CGFloat? = nil, y: CGFloat? = nil, width: CGFloat? = nil, height: CGFloat? = nil) {
        let currentRect = editSession.effectiveCropRotateState.cropRect
        let newRect = CGRect(
            x: x ?? currentRect.minX,
            y: y ?? currentRect.minY,
            width: width ?? currentRect.width,
            height: height ?? currentRect.height
        )
        
        let newState = editSession.effectiveCropRotateState.withCropRect(newRect)
        editSession.updateCropRotateState(newState)
    }
    
    private func resetCrop() {
        let newState = editSession.effectiveCropRotateState.withCropRect(
            CGRect(x: 0, y: 0, width: 1, height: 1)
        )
        editSession.updateCropRotateState(newState)
    }
    
    private func applyCenterCrop(_ percentage: CGFloat) {
        let size = percentage
        let offset = (1.0 - percentage) / 2.0
        let newRect = CGRect(x: offset, y: offset, width: size, height: size)
        
        let newState = editSession.effectiveCropRotateState.withCropRect(newRect)
        editSession.updateCropRotateState(newState)
    }
    
    private func togglePrecisionMode() {
        precisionMode.toggle()
    }
    
    private func resetAllTransforms() {
        editSession.updateCropRotateState(.identity)
    }
}

// MARK: - Crop Tools Enum

enum CropTool: String, CaseIterable {
    case crop = "crop"
    case rotate = "rotate"
    case flip = "flip"
    case aspectRatio = "aspectRatio"
    
    var displayName: String {
        switch self {
        case .crop: return "Crop"
        case .rotate: return "Rotate"
        case .flip: return "Flip"
        case .aspectRatio: return "Aspect"
        }
    }
    
    var iconName: String {
        switch self {
        case .crop: return "crop"
        case .rotate: return "rotate.right"
        case .flip: return "flip.horizontal"
        case .aspectRatio: return "rectangle.ratio.3.to.4"
        }
    }
}

#Preview {
    MacCropRotateView(editSession: EditSession.preview)
        .frame(width: 800, height: 600)
}

#endif