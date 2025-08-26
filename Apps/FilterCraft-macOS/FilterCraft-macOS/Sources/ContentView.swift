import SwiftUI
import FilterCraftCore
import Combine
import AppKit
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @StateObject private var editSession = EditSession()
    @State private var selectedImage: NSImage?
    @State private var dragIsActive = false
    @State private var selectedFilterType: FilterType = .none
    @State private var showingBeforeAfter = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var showingInspector = true
    @State private var showingAdjustments = true
    
    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                // Left Panel - Filters & Adjustments
                leftPanel
                    .frame(minWidth: 250, maxWidth: 350)
                
                // Center Panel - Image Canvas
                centerPanel
                    .frame(minWidth: 400)
                
                // Right Panel - Inspector (Optional)
                if showingInspector {
                    rightPanel
                        .frame(minWidth: 200, maxWidth: 300)
                }
            }
        }
        .toolbar {
            ToolbarView(
                editSession: editSession,
                showingBeforeAfter: $showingBeforeAfter,
                showingInspector: $showingInspector,
                zoomScale: $zoomScale,
                onOpenImage: openImage,
                onSaveImage: saveImage,
                onReset: resetEdits
            )
        }
    }
    
    private var leftPanel: some View {
        VStack(spacing: 0) {
            // Filters Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Filters")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(FilterType.allCases, id: \.self) { filterType in
                            FilterButton(
                                filterType: filterType,
                                isSelected: selectedFilterType == filterType,
                                action: {
                                    selectedFilterType = filterType
                                    editSession.applyFilter(filterType)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
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
                        AdjustmentControlsView(adjustments: $editSession.adjustments)
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
    
    private var centerPanel: some View {
        ZStack {
            if let previewImage = editSession.previewImage {
                ImageCanvasView(
                    image: previewImage,
                    originalImage: showingBeforeAfter ? editSession.originalImage : nil,
                    zoomScale: $zoomScale,
                    showingBeforeAfter: $showingBeforeAfter
                )
            } else {
                DropZoneView(
                    dragIsActive: $dragIsActive,
                    onImageDropped: loadImageFromURL,
                    onOpenClicked: openImage
                )
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onDrop(of: [.image], isTargeted: $dragIsActive) { providers in
            handleImageDrop(providers)
        }
    }
    
    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            InspectorView(editSession: editSession)
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Actions
    
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
    
    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.canLoadObject(ofClass: NSImage.self) {
            provider.loadObject(ofClass: NSImage.self) { image, _ in
                if let nsImage = image as? NSImage {
                    DispatchQueue.main.async {
                        loadImage(nsImage)
                    }
                }
            }
            return true
        }
        
        return false
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