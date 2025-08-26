import SwiftUI
import FilterCraftCore

struct AdjustmentControlsView: View {
    @Binding var adjustments: ImageAdjustments
    
    var body: some View {
        VStack(spacing: 16) {
            AdjustmentSlider(
                title: "Brightness",
                value: $adjustments.brightness,
                range: -1...1,
                icon: "sun.max"
            )
            
            AdjustmentSlider(
                title: "Contrast",
                value: $adjustments.contrast,
                range: -1...1,
                icon: "circle.lefthalf.filled"
            )
            
            AdjustmentSlider(
                title: "Saturation",
                value: $adjustments.saturation,
                range: -1...1,
                icon: "paintbrush"
            )
            
            AdjustmentSlider(
                title: "Exposure",
                value: $adjustments.exposure,
                range: -2...2,
                icon: "camera.aperture"
            )
            
            AdjustmentSlider(
                title: "Highlights",
                value: $adjustments.highlights,
                range: -1...1,
                icon: "sun.and.horizon"
            )
            
            AdjustmentSlider(
                title: "Shadows",
                value: $adjustments.shadows,
                range: -1...1,
                icon: "moon"
            )
            
            AdjustmentSlider(
                title: "Warmth",
                value: $adjustments.warmth,
                range: -1...1,
                icon: "thermometer"
            )
            
            AdjustmentSlider(
                title: "Tint",
                value: $adjustments.tint,
                range: -1...1,
                icon: "drop.triangle"
            )
            
            if adjustments.hasAdjustments {
                Button("Reset All Adjustments") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        adjustments = ImageAdjustments()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 8)
            }
        }
        .padding()
    }
}

struct AdjustmentSlider: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    let icon: String
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(valueString)
                    .font(.caption)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(isNearZero ? .secondary : .primary)
                    .frame(minWidth: 40, alignment: .trailing)
            }
            
            HStack(spacing: 8) {
                Slider(
                    value: $value,
                    in: range,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .accentColor(isNearZero ? .secondary : .blue)
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        value = 0
                    }
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                .opacity(isNearZero ? 0.3 : 1.0)
                .disabled(isNearZero)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var isNearZero: Bool {
        abs(value) < 0.01
    }
    
    private var valueString: String {
        if isNearZero {
            return "0"
        }
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }
}