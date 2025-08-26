import SwiftUI
import FilterCraftCore

struct ImageDisplayView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        // Only show when we have an image - welcome state handled in ContentView
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
}