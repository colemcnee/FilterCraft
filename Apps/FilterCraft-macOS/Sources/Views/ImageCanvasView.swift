import SwiftUI
import CoreImage

struct ImageCanvasView: View {
    let image: CIImage
    let originalImage: CIImage?
    @Binding var zoomScale: CGFloat
    @Binding var showingBeforeAfter: Bool
    
    @State private var dragOffset = CGSize.zero
    @State private var cumulativeOffset = CGSize.zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(NSColor.textBackgroundColor)
                
                if showingBeforeAfter, let original = originalImage {
                    // Split view for before/after comparison
                    HStack(spacing: 0) {
                        // Before (Original)
                        ImageView(image: original)
                            .scaleEffect(zoomScale)
                            .offset(x: dragOffset.width + cumulativeOffset.width,
                                   y: dragOffset.height + cumulativeOffset.height)
                            .clipShape(Rectangle())
                            .overlay(
                                Text("BEFORE")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(4),
                                alignment: .topLeading
                            )
                        
                        // Divider
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                        
                        // After (Edited)
                        ImageView(image: image)
                            .scaleEffect(zoomScale)
                            .offset(x: dragOffset.width + cumulativeOffset.width,
                                   y: dragOffset.height + cumulativeOffset.height)
                            .clipShape(Rectangle())
                            .overlay(
                                Text("AFTER")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(4),
                                alignment: .topTrailing
                            )
                    }
                } else {
                    // Single image view
                    ImageView(image: image)
                        .scaleEffect(zoomScale)
                        .offset(x: dragOffset.width + cumulativeOffset.width,
                               y: dragOffset.height + cumulativeOffset.height)
                }
            }
            .clipped()
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = max(0.1, min(5.0, value))
                        zoomScale = newScale
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        cumulativeOffset.width += value.translation.width
                        cumulativeOffset.height += value.translation.height
                        dragOffset = .zero
                    }
            )
            .onReceive(NotificationCenter.default.publisher(for: .zoomIn)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = min(zoomScale * 1.5, 5.0)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomOut)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = max(zoomScale / 1.5, 0.1)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomActualSize)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    zoomScale = 1.0
                    cumulativeOffset = .zero
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .zoomToFit)) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    let imageSize = image.extent.size
                    let viewSize = geometry.size
                    
                    let scaleX = viewSize.width / imageSize.width
                    let scaleY = viewSize.height / imageSize.height
                    zoomScale = min(scaleX, scaleY) * 0.9 // 90% to leave some margin
                    cumulativeOffset = .zero
                }
            }
        }
    }
}

struct ImageView: View {
    let image: CIImage
    
    var body: some View {
        Image(decorative: cgImage, scale: 1.0)
            .interpolation(.high)
    }
    
    private var cgImage: CGImage {
        let context = CIContext()
        return context.createCGImage(image, from: image.extent) ?? CGImage.empty
    }
}

extension CGImage {
    static var empty: CGImage {
        let context = CIContext()
        let emptyImage = CIImage.empty()
        return context.createCGImage(emptyImage, from: CGRect(x: 0, y: 0, width: 1, height: 1))!
    }
}