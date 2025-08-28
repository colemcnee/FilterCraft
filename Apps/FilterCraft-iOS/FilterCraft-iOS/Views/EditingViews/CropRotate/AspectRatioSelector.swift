import SwiftUI
import FilterCraftCore

/// Interactive aspect ratio selector with visual previews
struct AspectRatioSelector: View {
    @ObservedObject var editSession: EditSession
    @State private var isExpanded = false
    
    private let buttonSize: CGFloat = 44
    private let expandedSpacing: CGFloat = 8
    private let animationDuration: Double = 0.3
    
    var body: some View {
        HStack(spacing: isExpanded ? expandedSpacing : 0) {
            if isExpanded {
                // Show all aspect ratio options
                ForEach(AspectRatio.allCases.prefix(7), id: \.self) { ratio in
                    aspectRatioButton(ratio)
                        .transition(.scale.combined(with: .opacity))
                }
            } else {
                // Show only current aspect ratio
                aspectRatioButton(editSession.effectiveCropRotateState.aspectRatio ?? .freeForm)
            }
        }
        .animation(.easeInOut(duration: animationDuration), value: isExpanded)
        .padding(.horizontal, 8)
    }
    
    private func aspectRatioButton(_ ratio: AspectRatio) -> some View {
        Button(action: {
            if isExpanded {
                selectAspectRatio(ratio)
            } else {
                toggleExpansion()
            }
        }) {
            ZStack {
                Circle()
                    .fill(isSelected(ratio) ? Color.blue : Color.black.opacity(0.6))
                    .frame(width: buttonSize, height: buttonSize)
                
                // Aspect ratio preview rectangle
                aspectRatioPreview(ratio)
                    .foregroundColor(.white)
                
                // Selection indicator
                if isSelected(ratio) && isExpanded {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: buttonSize + 4, height: buttonSize + 4)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected(ratio) && !isExpanded ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected(ratio))
    }
    
    private func aspectRatioPreview(_ ratio: AspectRatio) -> some View {
        Group {
            if let aspectValue = ratio.ratio {
                let size = calculatePreviewSize(for: aspectValue)
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: size.width, height: size.height)
            } else {
                // Free form - show variable size indicator
                Image(systemName: "crop")
                    .font(.system(size: 16, weight: .medium))
            }
        }
    }
    
    private func calculatePreviewSize(for aspectRatio: CGFloat) -> CGSize {
        let maxDimension: CGFloat = 20
        
        if aspectRatio > 1 {
            // Landscape
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait or square
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
    
    private func isSelected(_ ratio: AspectRatio) -> Bool {
        let currentRatio = editSession.effectiveCropRotateState.aspectRatio ?? .freeForm
        return currentRatio == ratio
    }
    
    private func selectAspectRatio(_ ratio: AspectRatio) {
        let currentState = editSession.effectiveCropRotateState
        let newRatio = (ratio == .freeForm) ? nil : ratio
        
        // Only update if different
        guard currentState.aspectRatio != newRatio else {
            toggleExpansion()
            return
        }
        
        var newCropRect = currentState.cropRect
        
        // Apply new aspect ratio constraint to current crop rectangle
        if let newRatio = newRatio {
            newCropRect = newRatio.constrain(rect: newCropRect, in: CGSize(width: 1, height: 1))
        }
        
        let newState = currentState
            .withAspectRatio(newRatio)
            .withCropRect(newCropRect)
        
        editSession.updateCropRotateState(newState)
        
        // Collapse after selection
        toggleExpansion()
    }
    
    private func toggleExpansion() {
        withAnimation(.easeInOut(duration: animationDuration)) {
            isExpanded.toggle()
        }
        
        // Auto-collapse after a delay if expanded
        if isExpanded {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if isExpanded {
                    withAnimation(.easeInOut(duration: animationDuration)) {
                        isExpanded = false
                    }
                }
            }
        }
    }
}

// MARK: - Compact Aspect Ratio Selector

/// Compact version for toolbar use
struct CompactAspectRatioSelector: View {
    @ObservedObject var editSession: EditSession
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: { showingPicker = true }) {
            HStack(spacing: 4) {
                aspectRatioIcon
                Text(currentRatio.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.6))
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingPicker) {
            AspectRatioPicker(editSession: editSession)
                .presentationDetents([.medium])
        }
    }
    
    private var currentRatio: AspectRatio {
        editSession.effectiveCropRotateState.aspectRatio ?? .freeForm
    }
    
    private var aspectRatioIcon: some View {
        Group {
            if let ratio = currentRatio.ratio {
                let size = calculateIconSize(for: ratio)
                RoundedRectangle(cornerRadius: 1)
                    .frame(width: size.width, height: size.height)
            } else {
                Image(systemName: "crop")
                    .font(.system(size: 12))
            }
        }
    }
    
    private func calculateIconSize(for aspectRatio: CGFloat) -> CGSize {
        let maxDimension: CGFloat = 12
        
        if aspectRatio > 1 {
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
}

// MARK: - Full Aspect Ratio Picker Sheet

struct AspectRatioPicker: View {
    @ObservedObject var editSession: EditSession
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(AspectRatio.allCases, id: \.self) { ratio in
                        aspectRatioCard(ratio)
                    }
                }
                .padding()
            }
            .navigationTitle("Aspect Ratio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func aspectRatioCard(_ ratio: AspectRatio) -> some View {
        Button(action: { selectRatio(ratio) }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 60)
                    
                    if let aspectValue = ratio.ratio {
                        let size = calculateCardPreviewSize(for: aspectValue)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected(ratio) ? Color.blue : Color.gray)
                            .frame(width: size.width, height: size.height)
                    } else {
                        Image(systemName: ratio.iconName)
                            .font(.title2)
                            .foregroundColor(isSelected(ratio) ? .blue : .gray)
                    }
                    
                    if isSelected(ratio) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(height: 60)
                    }
                }
                
                Text(ratio.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if ratio != .freeForm && ratio != .custom {
                    Text(ratio.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func calculateCardPreviewSize(for aspectRatio: CGFloat) -> CGSize {
        let maxDimension: CGFloat = 40
        
        if aspectRatio > 1 {
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
    
    private func isSelected(_ ratio: AspectRatio) -> Bool {
        let currentRatio = editSession.effectiveCropRotateState.aspectRatio ?? .freeForm
        return currentRatio == ratio
    }
    
    private func selectRatio(_ ratio: AspectRatio) {
        let currentState = editSession.effectiveCropRotateState
        let newRatio = (ratio == .freeForm) ? nil : ratio
        
        guard currentState.aspectRatio != newRatio else { return }
        
        var newCropRect = currentState.cropRect
        
        if let newRatio = newRatio {
            newCropRect = newRatio.constrain(rect: newCropRect, in: CGSize(width: 1, height: 1))
        }
        
        let newState = currentState
            .withAspectRatio(newRatio)
            .withCropRect(newCropRect)
        
        editSession.updateCropRotateState(newState)
        
        // Brief delay before dismissing for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

#Preview("AspectRatioSelector") {
    AspectRatioSelector(editSession: EditSession.preview)
        .frame(width: 300, height: 60)
        .background(Color.black)
}

#Preview("CompactAspectRatioSelector") {
    CompactAspectRatioSelector(editSession: EditSession.preview)
}

#Preview("AspectRatioPicker") {
    AspectRatioPicker(editSession: EditSession.preview)
}
