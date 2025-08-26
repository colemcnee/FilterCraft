import SwiftUI
import FilterCraftCore

struct ToolbarView: ToolbarContent {
    let editSession: EditSession
    @Binding var showingBeforeAfter: Bool
    @Binding var showingInspector: Bool
    @Binding var zoomScale: CGFloat
    let onOpenImage: () -> Void
    let onSaveImage: () -> Void
    let onReset: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            Button(action: onOpenImage) {
                Image(systemName: "folder.badge.plus")
            }
            .help("Open Image (⌘O)")
            
            Button(action: onSaveImage) {
                Image(systemName: "square.and.arrow.down")
            }
            .help("Save Image (⌘S)")
            .disabled(editSession.originalImage == nil)
        }
        
        ToolbarItemGroup(placement: .principal) {
            HStack(spacing: 12) {
                // Processing Status
                if case .processing(let progress, let operation) = editSession.processingState {
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .frame(width: 100)
                        Text(operation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if editSession.hasEdits {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                        Text("Modified")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        
        ToolbarItemGroup(placement: .automatic) {
            HStack(spacing: 8) {
                // Zoom Controls
                Menu {
                    Button("Actual Size (⌘0)") {
                        zoomScale = 1.0
                    }
                    Button("Fit to Window (⌘9)") {
                        // This would be calculated based on the image and view size
                        zoomScale = 0.5
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
                
                Divider()
                    .frame(height: 20)
                
                // Before/After Toggle
                Button(action: {
                    showingBeforeAfter.toggle()
                }) {
                    Image(systemName: showingBeforeAfter ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                }
                .help("Toggle Before/After (⌘B)")
                .disabled(editSession.originalImage == nil || !editSession.hasEdits)
                
                // Inspector Toggle
                Button(action: {
                    showingInspector.toggle()
                }) {
                    Image(systemName: showingInspector ? "sidebar.right" : "sidebar.left")
                }
                .help("Toggle Inspector (⌘⌥I)")
                
                Divider()
                    .frame(height: 20)
                
                // Reset Button
                Button(action: onReset) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("Reset All Edits (⌘⇧R)")
                .disabled(editSession.originalImage == nil || !editSession.hasEdits)
            }
        }
    }
}