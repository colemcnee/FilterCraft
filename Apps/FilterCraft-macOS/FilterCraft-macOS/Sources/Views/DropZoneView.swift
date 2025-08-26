import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var dragIsActive: Bool
    let onImageDropped: (URL) -> Void
    let onOpenClicked: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    dragIsActive ? Color.blue : Color.secondary,
                    style: StrokeStyle(
                        lineWidth: 2,
                        lineCap: .round,
                        dash: [8, 4]
                    )
                )
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(dragIsActive ? Color.blue.opacity(0.1) : Color.clear)
                )
                .animation(.easeInOut(duration: 0.2), value: dragIsActive)
            
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundColor(dragIsActive ? .blue : .secondary)
                    .scaleEffect(dragIsActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: dragIsActive)
                
                VStack(spacing: 8) {
                    Text(dragIsActive ? "Drop image here" : "Drag & Drop Image")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(dragIsActive ? .blue : .primary)
                    
                    if !dragIsActive {
                        Text("or")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Choose from Files") {
                            onOpenClicked()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                
                if !dragIsActive {
                    VStack(spacing: 4) {
                        Text("Supported formats:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("JPEG, PNG, HEIF, TIFF, GIF")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: dragIsActive)
        }
        .padding(40)
        .onDrop(of: [.image], isTargeted: $dragIsActive) { providers in
            handleDrop(providers)
        }
    }
    
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.image.identifier) { item, error in
                if let url = item as? URL {
                    DispatchQueue.main.async {
                        onImageDropped(url)
                    }
                } else if let data = item as? Data,
                          let _ = NSImage(data: data) {
                    // Handle data-based drops by creating a temporary file
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("jpg")
                    
                    do {
                        try data.write(to: tempURL)
                        DispatchQueue.main.async {
                            onImageDropped(tempURL)
                        }
                    } catch {
                        print("Failed to write temporary image: \(error)")
                    }
                }
            }
            return true
        }
        
        return false
    }
}