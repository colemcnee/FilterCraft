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
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.brightness : editSession.userAdjustments.brightness
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.brightness = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.brightness = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "sun.max",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Contrast",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.contrast : editSession.userAdjustments.contrast
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.contrast = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.contrast = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "circle.lefthalf.filled",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Saturation",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.saturation : editSession.userAdjustments.saturation
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.saturation = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.saturation = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "paintbrush",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Exposure",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.exposure : editSession.userAdjustments.exposure
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.exposure = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.exposure = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -2...2,
                        icon: "camera.aperture",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Highlights",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.highlights : editSession.userAdjustments.highlights
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.highlights = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.highlights = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "sun.and.horizon",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Shadows",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.shadows : editSession.userAdjustments.shadows
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.shadows = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.shadows = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "moon",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Warmth",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.warmth : editSession.userAdjustments.warmth
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.warmth = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.warmth = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "thermometer",
                        editSession: editSession
                    )
                    
                    AdjustmentSlider(
                        title: "Tint",
                        value: Binding(
                            get: { 
                                editSession.isPreviewingAdjustments ? editSession.previewAdjustments.tint : editSession.userAdjustments.tint
                            },
                            set: { newValue in
                                if editSession.isPreviewingAdjustments {
                                    var newPreviewAdjustments = editSession.previewAdjustments
                                    newPreviewAdjustments.tint = newValue
                                    editSession.updatePreviewAdjustments(newPreviewAdjustments)
                                } else {
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.tint = newValue
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            }
                        ),
                        range: -1...1,
                        icon: "drop.triangle",
                        editSession: editSession
                    )
                }
            }
            
            if editSession.userAdjustments.hasAdjustments {
                Button("Reset Manual Adjustments") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        editSession.updateUserAdjustments(ImageAdjustments())
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
    let editSession: EditSession
    
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
                        if editing {
                            // Start preview mode when slider interaction begins
                            editSession.startPreviewingAdjustments()
                        } else {
                            // Commit changes when slider interaction ends
                            editSession.commitPreviewAdjustments()
                        }
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