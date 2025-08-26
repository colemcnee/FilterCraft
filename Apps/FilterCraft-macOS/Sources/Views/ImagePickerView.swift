import SwiftUI
import AppKit

struct ImagePickerView: NSViewControllerRepresentable {
    let onImageSelected: (NSImage) -> Void
    
    func makeNSViewController(context: Context) -> NSViewController {
        let controller = ImagePickerViewController()
        controller.onImageSelected = onImageSelected
        return controller
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // No updates needed
    }
}

class ImagePickerViewController: NSViewController {
    var onImageSelected: ((NSImage) -> Void)?
    
    override func viewDidAppear() {
        super.viewDidAppear()
        presentImagePicker()
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
        
        openPanel.begin { [weak self] result in
            DispatchQueue.main.async {
                if result == .OK, 
                   let url = openPanel.url,
                   let image = NSImage(contentsOf: url) {
                    self?.onImageSelected?(image)
                }
                self?.dismiss(nil)
            }
        }
    }
}