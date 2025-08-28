import FilterCraftCore
import SwiftUI
import UniformTypeIdentifiers

struct MainImageView: View {
    @ObservedObject var editSession: EditSession
    @Binding var showingBeforeAfter: Bool
    @Binding var zoomScale: CGFloat
    @Binding var dragIsActive: Bool
    
    let onImageDropped: (URL) -> Void
    let onOpenClicked: () -> Void
    
    var body: some View {
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
                    onImageDropped: onImageDropped,
                    onOpenClicked: onOpenClicked
                )
            }
        }
        .background(Color(NSColor.textBackgroundColor))
        .onDrop(of: [.image], isTargeted: $dragIsActive) { providers in
            handleImageDrop(providers)
        }
    }
    
    private func handleImageDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        if provider.canLoadObject(ofClass: NSImage.self) {
            provider.loadObject(ofClass: NSImage.self) { image, _ in
                if let nsImage = image as? NSImage {
                    // Convert NSImage to temporary URL for consistency with onImageDropped
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension("jpg")
                    
                    if let tiffData = nsImage.tiffRepresentation,
                       let bitmapImage = NSBitmapImageRep(data: tiffData),
                       let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) {
                        do {
                            try jpegData.write(to: tempURL)
                            DispatchQueue.main.async {
                                onImageDropped(tempURL)
                            }
                        } catch {
                            print("Failed to write temporary image: \(error)")
                        }
                    }
                }
            }
            return true
        }
        
        return false
    }
}
