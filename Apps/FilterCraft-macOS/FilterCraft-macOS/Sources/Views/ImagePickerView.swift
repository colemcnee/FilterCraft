import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ImagePickerView: View {
    let onImageSelected: (NSImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Selecting image...")
            .onAppear {
                presentImagePicker()
            }
    }
    
    private func presentImagePicker() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.image, .jpeg, .png, .heif, .tiff, .gif]
        openPanel.title = "Select Image"
        openPanel.prompt = "Choose"
        
        openPanel.begin { result in
            DispatchQueue.main.async {
                if result == .OK, 
                   let url = openPanel.url,
                   let image = NSImage(contentsOf: url) {
                    onImageSelected(image)
                }
                dismiss()
            }
        }
    }
}
