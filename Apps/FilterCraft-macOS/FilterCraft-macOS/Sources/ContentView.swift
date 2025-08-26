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
                MainImageView(
                    editSession: editSession,
                    showingBeforeAfter: $showingBeforeAfter,
                    zoomScale: $zoomScale,
                    dragIsActive: $dragIsActive,
                    onImageDropped: loadImageFromURL,
                    onOpenClicked: openImage
                )
                .frame(minWidth: 400)
                
                // Right Panel - Inspector (Optional)
                if showingInspector {
                    InspectorView(editSession: editSession)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
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