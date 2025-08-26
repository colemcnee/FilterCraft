import SwiftUI
import FilterCraftCore

struct ImageDisplayView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        Group {
            if editSession.previewImage != nil {
                AsyncImageView(editSession: editSession)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .overlay(alignment: .topTrailing) {
                        if editSession.hasEdits {
                            Button("Reset") {
                                Task {
                                    await editSession.resetToOriginal()
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .padding(12)
                        }
                    }
            } else {
                // Placeholder for no image loaded
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(maxHeight: 400)
                    .overlay(
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("Select a photo to begin editing")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
    }
}