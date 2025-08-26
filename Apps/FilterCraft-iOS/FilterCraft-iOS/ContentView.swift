import SwiftUI
import FilterCraftCore

struct ContentView: View {
    @StateObject private var editSession = EditSession()
    
    var body: some View {
        NavigationView {
            if editSession.originalImage != nil {
                // Editing mode - compact layout with scroll
                ScrollView {
                    VStack(spacing: 24) {
                        ImageDisplayView(editSession: editSession)
                        FilterSelectionView(editSession: editSession)
                        AdjustmentControlsView(editSession: editSession)
                        ExportOptionsView(editSession: editSession)
                    }
                    .padding(.horizontal)
                }
                .navigationTitle("FilterCraft")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                // Welcome mode - spacious layout
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 32) {
                        // App icon or logo area
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 16) {
                            Text("FilterCraft")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Transform your photos with professional filters and adjustments")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        PhotoPickerView(editSession: editSession)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                    Spacer() // Extra spacer to push content up slightly
                }
                .navigationTitle("")
                .navigationBarHidden(true)
            }
        }
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