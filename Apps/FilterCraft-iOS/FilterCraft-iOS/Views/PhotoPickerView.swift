import FilterCraftCore
import PhotosUI
import SwiftUI

struct PhotoPickerView: View {
    @ObservedObject var editSession: EditSession
    @State private var selectedPhoto: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 16) {
            if editSession.originalImage == nil {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.title2)
                        Text("Select Photo")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
                    )
                }
            } else {
                // Show current image info and option to select new photo
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Image Loaded")
                            .font(.headline)
                        
                        if let extent = editSession.originalImage?.extent {
                            Text("\(Int(extent.width)) × \(Int(extent.height))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Change")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .onChange(of: selectedPhoto) { _ in
            Task {
                if let selectedPhoto = selectedPhoto {
                    await loadSelectedPhoto(selectedPhoto)
                }
            }
        }
    }
    
    private func loadSelectedPhoto(_ photo: PhotosPickerItem) async {
        do {
            guard let imageData = try await photo.loadTransferable(type: Data.self) else {
                print("Failed to load photo data")
                return
            }
            
            guard let uiImage = UIImage(data: imageData) else {
                print("Failed to create UIImage from data")
                return
            }
            
            guard let ciImage = CIImage(image: uiImage) else {
                print("Failed to create CIImage from UIImage")
                return
            }
            
            await MainActor.run {
                Task {
                    await editSession.loadImage(ciImage)
                }
            }
        } catch {
            print("Error loading photo: \(error)")
        }
    }
}
