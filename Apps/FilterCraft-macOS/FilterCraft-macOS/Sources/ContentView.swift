import AppKit
import Combine
import FilterCraftCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @ObservedObject var editSession: EditSession
    @ObservedObject var appState: AppState
    @State private var selectedImage: NSImage?
    @State private var dragIsActive = false
    @State private var selectedFilterType: FilterType = .none
    @State private var showingBeforeAfter = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var showingInspector = true
    @State private var showingAdjustments = true
    
    // Crop mode state
    @State private var cropWorkingState = CropRotateState.identity
    
    // Computed property for crop mode
    private var isInCropMode: Bool {
        get { appState.isInCropMode }
        nonmutating set { appState.isInCropMode = newValue }
    }
    
    var body: some View {
        GeometryReader { _ in
            HSplitView {
                // Left Panel - Filters & Adjustments (hide during crop mode)
                if !isInCropMode {
                    leftPanel
                        .frame(minWidth: 250, maxWidth: 350)
                        .transition(.move(edge: .leading))
                }
                
                // Center Panel - Image Canvas with dynamic content
                VStack(spacing: 0) {
                    // Dynamic toolbar based on mode
                    if isInCropMode {
                        cropModeToolbar
                    } else {
                        normalModeToolbar
                    }
                    
                    // Main image area with conditional crop overlay
                    ZStack {
                        MainImageView(
                            editSession: editSession,
                            showingBeforeAfter: $showingBeforeAfter,
                            zoomScale: $zoomScale,
                            dragIsActive: $dragIsActive,
                            onImageDropped: loadImageFromURL,
                            onOpenClicked: openImage
                        )
                        
                        // Show crop overlay only in crop mode
                        if isInCropMode {
                            MacCropOverlay(editSession: editSession)
                                .transition(.opacity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: isInCropMode ? 600 : 400)
                
                // Right Panel - Inspector (show crop controls during crop mode)
                if showingInspector {
                    VStack {
                        if isInCropMode {
                            cropInspectorControls
                        } else {
                            InspectorView(editSession: editSession)
                                .padding()
                        }
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    .frame(minWidth: 250, maxWidth: 300)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .navigationTitle(isInCropMode ? "Crop & Rotate" : "FilterCraft")
        .animation(.easeInOut(duration: 0.3), value: isInCropMode)
        .onKeyDown(.escape) {
            if isInCropMode {
                cancelCropMode()
                return true
            }
            return false
        }
        .onKeyDown(.return) {
            if isInCropMode {
                applyCropMode()
                return true
            }
            return false
        }
        .onReceive(NotificationCenter.default.publisher(for: .enterCropMode)) { _ in
            enterCropMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exitCropMode)) { _ in
            cancelCropMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .applyCropMode)) { _ in
            applyCropMode()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetCropMode)) { _ in
            resetCropMode()
        }
        .toolbar {
            ToolbarView(
                editSession: editSession,
                showingBeforeAfter: $showingBeforeAfter,
                showingInspector: $showingInspector,
                zoomScale: $zoomScale,
                onOpenImage: openImage,
                onSaveImage: saveImage,
                onReset: resetEdits,
                onEnterCropMode: enterCropMode
            )
        }
    }
    
    // MARK: - Dynamic Toolbars
    
    @ViewBuilder
    private var normalModeToolbar: some View {
        HStack {
            Button(action: openImage) {
                Image(systemName: "folder.badge.plus")
            }
            .help("Open Image (⌘O)")
            
            Button(action: saveImage) {
                Image(systemName: "square.and.arrow.down")
            }
            .help("Save Image (⌘S)")
            .disabled(editSession.originalImage == nil)
            
            Spacer()
            
            // Crop & Rotate button
            Button(action: enterCropMode) {
                Label("Crop & Rotate", systemImage: "crop.rotate")
            }
            .disabled(editSession.originalImage == nil)
            .help("Crop & Rotate (⌘⇧R)")
            
            Spacer()
            
            // Zoom controls
            Menu {
                Button("Actual Size (⌘0)") {
                    zoomScale = 1.0
                }
                Button("Fit to Window (⌘9)") {
                    zoomScale = 0.5 // Would be calculated
                }
                Divider()
                Button("Zoom In (⌘+)") {
                    zoomScale = min(zoomScale * 1.5, 5.0)
                }
                Button("Zoom Out (⌘-)") {
                    zoomScale = max(zoomScale / 1.5, 0.1)
                }
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "magnifyingglass")
                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption)
                }
            }
            .frame(minWidth: 60)
            .disabled(editSession.originalImage == nil)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private var cropModeToolbar: some View {
        HStack {
            Button("Cancel") {
                cancelCropMode()
            }
            .keyboardShortcut(.escape)
            .buttonStyle(.bordered)
            
            Spacer()
            
            HStack(spacing: 16) {
                Image(systemName: "crop.rotate")
                    .foregroundColor(.accentColor)
                Text("Crop & Rotate")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Reset") {
                    resetCropMode()
                }
                .keyboardShortcut("r")
                .buttonStyle(.bordered)
                
                Button("Apply") {
                    applyCropMode()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.accentColor.opacity(0.1))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.accentColor.opacity(0.3)),
            alignment: .bottom
        )
    }
    
    // MARK: - Crop Inspector Controls
    
    @ViewBuilder
    private var cropInspectorControls: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crop & Rotate")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Adjust the crop area and rotation")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Aspect ratio controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Aspect Ratio")
                        .font(.subheadline.weight(.medium))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        aspectRatioButton("Free", aspectRatio: nil)
                        aspectRatioButton("1:1", aspectRatio: .square)
                        aspectRatioButton("4:3", aspectRatio: .traditional)
                        aspectRatioButton("16:9", aspectRatio: .widescreen)
                        aspectRatioButton("3:4", aspectRatio: .portrait)
                        aspectRatioButton("Golden", aspectRatio: .golden)
                    }
                }
                
                Divider()
                
                // Rotation controls  
                VStack(alignment: .leading, spacing: 12) {
                    Text("Rotation")
                        .font(.subheadline.weight(.medium))
                    
                    HStack(spacing: 8) {
                        Button("-90°") {
                            let newAngle = cropWorkingState.rotationAngle - .pi/2
                            cropWorkingState = cropWorkingState.withRotation(normalizeAngle(newAngle))
                            updateWorkingState()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("+90°") {
                            let newAngle = cropWorkingState.rotationAngle + .pi/2
                            cropWorkingState = cropWorkingState.withRotation(normalizeAngle(newAngle))
                            updateWorkingState()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Spacer()
                        
                        if cropWorkingState.rotationAngle != 0 {
                            Text("\(Int(cropWorkingState.rotationDegrees))°")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Fine rotation slider
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fine Adjust")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: Binding(
                                get: { cropWorkingState.rotationAngle },
                                set: { angle in
                                    cropWorkingState = cropWorkingState.withRotation(angle)
                                    updateWorkingState()
                                }
                            ),
                            in: -.pi...(.pi)
                        )
                        .controlSize(.small)
                    }
                }
                
                Divider()
                
                // Flip controls
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flip")
                        .font(.subheadline.weight(.medium))
                    
                    Toggle("Flip Horizontally", isOn: Binding(
                        get: { cropWorkingState.isFlippedHorizontally },
                        set: { isFlipped in
                            cropWorkingState = cropWorkingState.withHorizontalFlip(isFlipped)
                            updateWorkingState()
                        }
                    ))
                    .toggleStyle(.checkbox)
                    
                    Toggle("Flip Vertically", isOn: Binding(
                        get: { cropWorkingState.isFlippedVertically },
                        set: { isFlipped in
                            cropWorkingState = cropWorkingState.withVerticalFlip(isFlipped)
                            updateWorkingState()
                        }
                    ))
                    .toggleStyle(.checkbox)
                }
                
                Divider()
                
                // Transform summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Transform")
                        .font(.subheadline.weight(.medium))
                    
                    Text(cropWorkingState.transformationDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func aspectRatioButton(_ title: String, aspectRatio: AspectRatio?) -> some View {
        let isSelected = cropWorkingState.aspectRatio == aspectRatio
        
        return Button(action: {
            cropWorkingState = cropWorkingState.withAspectRatio(aspectRatio)
            updateWorkingState()
        }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                .foregroundColor(isSelected ? .white : .accentColor)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Left Panel (unchanged)
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Filters Section
            FilterLibraryView(
                editSession: editSession,
                selectedFilterType: $selectedFilterType
            )
            .frame(maxHeight: .infinity)
            
            Divider()
            
            // Adjustments Section
            if showingAdjustments {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Adjustments")
                            .font(.headline)
                        Spacer()
                        Button(action: { showingAdjustments.toggle() }) {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    
                    ScrollView {
                        AdjustmentControlsView(editSession: editSession)
                    }
                }
                .frame(maxHeight: .infinity)
            } else {
                HStack {
                    Text("Adjustments")
                        .font(.headline)
                    Spacer()
                    Button(action: { showingAdjustments.toggle() }) {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Crop Mode Actions
    
    private func enterCropMode() {
        cropWorkingState = editSession.cropRotateState
        withAnimation(.easeInOut(duration: 0.3)) {
            isInCropMode = true
        }
    }
    
    private func cancelCropMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isInCropMode = false
        }
        // Reset to original state
        cropWorkingState = editSession.cropRotateState
    }
    
    private func applyCropMode() {
        editSession.updateCropRotateState(cropWorkingState)
        withAnimation(.easeInOut(duration: 0.3)) {
            isInCropMode = false
        }
    }
    
    private func resetCropMode() {
        cropWorkingState = .identity
        updateWorkingState()
    }
    
    private func updateWorkingState() {
        editSession.updateCropRotateStateTemporary(cropWorkingState)
    }
    
    private func normalizeAngle(_ angle: Float) -> Float {
        var normalized = angle
        while normalized > .pi { normalized -= 2 * .pi }
        while normalized < -.pi { normalized += 2 * .pi }
        return normalized
    }
    
    // MARK: - Actions (unchanged)
    
    private func openImage() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.image, .jpeg, .png, .heif, .tiff, .gif]
        openPanel.title = "Select Image"
        openPanel.prompt = "Choose"
        
        openPanel.begin { result in
            if result == .OK,
               let url = openPanel.url,
               let image = NSImage(contentsOf: url) {
                DispatchQueue.main.async {
                    loadImage(image)
                }
            }
        }
    }
    
    private func saveImage() {
        guard editSession.originalImage != nil else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg, .png, .heif]
        savePanel.nameFieldStringValue = "FilterCraft_Export"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                Task { @MainActor in
                    await exportImage(to: url)
                }
            }
        }
    }
    
    private func resetEdits() {
        Task {
            await editSession.resetToOriginal()
        }
    }
    
    private func loadImage(_ image: NSImage) {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let ciImage = CIImage(cgImage: cgImage)
            Task {
                await editSession.loadImage(ciImage)
                selectedFilterType = .none
            }
        }
    }
    
    private func loadImageFromURL(_ url: URL) {
        if let image = NSImage(contentsOf: url) {
            loadImage(image)
        }
    }
    
    private func exportImage(to url: URL) async {
        let format: ImageExportFormat
        switch url.pathExtension.lowercased() {
        case "png":
            format = .png
        case "heif":
            format = .heif
        default:
            format = .jpeg
        }
        
        guard let imageData = await editSession.exportImage(format: format, quality: 0.9) else {
            return
        }
        
        do {
            try imageData.write(to: url)
        } catch {
            print("Failed to save image: \(error)")
        }
    }
}

// MARK: - Key Event Handling Extension

extension View {
    func onKeyDown(_ key: KeyEquivalent, perform action: @escaping () -> Bool) -> some View {
        self.background(KeyEventHandling(key: key, action: action))
    }
}

struct KeyEventHandling: NSViewRepresentable {
    let key: KeyEquivalent
    let action: () -> Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.keyHandler = { event in
            if event.charactersIgnoringModifiers == String(key.character) {
                return action()
            }
            return false
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

class KeyView: NSView {
    var keyHandler: ((NSEvent) -> Bool)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func keyDown(with event: NSEvent) {
        if let handler = keyHandler, handler(event) {
            return
        }
        super.keyDown(with: event)
    }
}