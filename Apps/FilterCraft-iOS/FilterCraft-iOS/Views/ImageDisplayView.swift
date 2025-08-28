import FilterCraftCore
import SwiftUI

struct ImageDisplayView: View {
    @ObservedObject var editSession: EditSession
    @State var showingCrop: Bool = false
    
    var body: some View {
        // Only show when we have an image - welcome state handled in ContentView
        ZStack(alignment: .topLeading) {
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
        }
        .overlay(alignment: .bottomTrailing) { // Crop rotate button on top right
            Button {
                showingCrop.toggle()
            } label: {
                Image(systemName: "crop.rotate")
                    .font(.title2)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
                    .foregroundColor(.white)
            }
            .padding(12)
        }
        .fullScreenCover(isPresented: $showingCrop) {
            CropRotateView(editSession: editSession)
        }
    }
}
