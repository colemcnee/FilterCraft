import SwiftUI
import FilterCraftCore

struct ContentView: View {
    @StateObject private var editSession = EditSession()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ImageDisplayView(editSession: editSession)
                    PhotoPickerView(editSession: editSession)
                    
                    if editSession.originalImage != nil {
                        FilterSelectionView(editSession: editSession)
                        AdjustmentControlsView(editSession: editSession)
                        ExportOptionsView(editSession: editSession)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("FilterCraft")
            .navigationBarTitleDisplayMode(.inline)
        }
        .padding(.vertical, 20)
    }
}

// MARK: - AsyncImageView (keeping existing implementation)
struct AsyncImageView: View {
    @ObservedObject var editSession: EditSession
    @State private var uiImage: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .onAppear {
            if let previewImage = editSession.previewImage {
                convertCIImageToUIImage(previewImage)
            }
        }
        .onReceive(editSession.$previewImage) { newPreviewImage in
            guard let ciImage = newPreviewImage else { 
                uiImage = nil
                return 
            }
            convertCIImageToUIImage(ciImage)
        }
    }
    
    private func convertCIImageToUIImage(_ ciImage: CIImage) {
        Task {
            let context = CIContext(options: [.useSoftwareRenderer: false])
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let newUIImage = UIImage(cgImage: cgImage)
                await MainActor.run {
                    uiImage = newUIImage
                }
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}