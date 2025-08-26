import SwiftUI
import FilterCraftCore

struct AdjustmentControlsView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(spacing: 16) {
            // Show base adjustments from filter (if any)
            if editSession.baseAdjustments.hasAdjustments {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "camera.filters")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("From Filter")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    BaseAdjustmentDisplay(adjustments: editSession.baseAdjustments)
                }
                .padding(.bottom, 8)
                
                Divider()
            }
            
            // Manual adjustments
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Manual Adjustments")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    AdjustmentSlider(
                        title: "Brightness",
                        value: $editSession.userAdjustments.brightness,
                        range: -1...1,
                        icon: "sun.max"
                    )
                    
                    AdjustmentSlider(
                        title: "Contrast",
                        value: $editSession.userAdjustments.contrast,
                        range: -1...1,
                        icon: "circle.lefthalf.filled"
                    )
                    
                    AdjustmentSlider(
                        title: "Saturation",
                        value: $editSession.userAdjustments.saturation,
                        range: -1...1,
                        icon: "paintbrush"
                    )
                    
                    AdjustmentSlider(
                        title: "Exposure",
                        value: $editSession.userAdjustments.exposure,
                        range: -2...2,
                        icon: "camera.aperture"
                    )
                    
                    AdjustmentSlider(
                        title: "Highlights",
                        value: $editSession.userAdjustments.highlights,
                        range: -1...1,
                        icon: "sun.and.horizon"
                    )
                    
                    AdjustmentSlider(
                        title: "Shadows",
                        value: $editSession.userAdjustments.shadows,
                        range: -1...1,
                        icon: "moon"
                    )
                    
                    AdjustmentSlider(
                        title: "Warmth",
                        value: $editSession.userAdjustments.warmth,
                        range: -1...1,
                        icon: "thermometer"
                    )
                    
                    AdjustmentSlider(
                        title: "Tint",
                        value: $editSession.userAdjustments.tint,
                        range: -1...1,
                        icon: "drop.triangle"
                    )
                }
            }
            
            if editSession.userAdjustments.hasAdjustments {
                Button("Reset Manual Adjustments") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        editSession.userAdjustments = ImageAdjustments()
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

struct BaseAdjustmentDisplay: View {
    let adjustments: ImageAdjustments
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if adjustments.brightness != 0 {
                BaseAdjustmentRow(label: "Brightness", value: adjustments.brightness, icon: "sun.max")
            }
            if adjustments.contrast != 0 {
                BaseAdjustmentRow(label: "Contrast", value: adjustments.contrast, icon: "circle.lefthalf.filled")
            }
            if adjustments.saturation != 0 {
                BaseAdjustmentRow(label: "Saturation", value: adjustments.saturation, icon: "paintbrush")
            }
            if adjustments.exposure != 0 {
                BaseAdjustmentRow(label: "Exposure", value: adjustments.exposure, icon: "camera.aperture")
            }
            if adjustments.highlights != 0 {
                BaseAdjustmentRow(label: "Highlights", value: adjustments.highlights, icon: "sun.and.horizon")
            }
            if adjustments.shadows != 0 {
                BaseAdjustmentRow(label: "Shadows", value: adjustments.shadows, icon: "moon")
            }
            if adjustments.warmth != 0 {
                BaseAdjustmentRow(label: "Warmth", value: adjustments.warmth, icon: "thermometer")
            }
            if adjustments.tint != 0 {
                BaseAdjustmentRow(label: "Tint", value: adjustments.tint, icon: "drop.triangle")
            }
        }
        .padding(.horizontal, 4)
    }
}

struct BaseAdjustmentRow: View {
    let label: String
    let value: Float
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(.blue.opacity(0.7))
                .frame(width: 16)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.blue.opacity(0.8))
            
            Spacer()
            
            Text(valueString)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.blue)
        }
    }
    
    private var valueString: String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }
}