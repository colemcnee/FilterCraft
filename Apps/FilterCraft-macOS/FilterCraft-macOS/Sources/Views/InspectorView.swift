import SwiftUI
import FilterCraftCore

struct InspectorView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image Information
                imageInfoSection
                
                Divider()
                
                // Filter Information
                filterInfoSection
                
                Divider()
                
                // Adjustments Summary
                adjustmentsSection
                
                Divider()
                
                // Session Statistics
                sessionStatsSection
                
                Divider()
                
                // Edit History
                editHistorySection
            }
            .padding()
        }
    }
    
    private var imageInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image Info")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                if let originalImage = editSession.originalImage {
                    InfoRow(label: "Size", value: "\(Int(originalImage.extent.width)) × \(Int(originalImage.extent.height))")
                    InfoRow(label: "Extent", value: formatRect(originalImage.extent))
                } else {
                    Text("No image loaded")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    private var filterInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Applied Filter")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                if let appliedFilter = editSession.appliedFilter, appliedFilter.isEffective {
                    InfoRow(label: "Type", value: appliedFilter.filterType.displayName)
                    InfoRow(label: "Intensity", value: "\(Int(appliedFilter.intensity * 100))%")
                    InfoRow(label: "Applied", value: formatTime(appliedFilter.appliedAt))
                } else {
                    Text("No filter applied")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    private var adjustmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adjustments")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                // Base adjustments from filter
                if editSession.baseAdjustments.hasAdjustments {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From Filter")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        adjustmentRows(for: editSession.baseAdjustments, color: .blue)
                    }
                }
                
                // User manual adjustments
                if editSession.userAdjustments.hasAdjustments {
                    if editSession.baseAdjustments.hasAdjustments {
                        Divider()
                            .padding(.vertical, 2)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Manual")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        adjustmentRows(for: editSession.userAdjustments, color: .primary)
                    }
                }
                
                // No adjustments message
                if !editSession.baseAdjustments.hasAdjustments && !editSession.userAdjustments.hasAdjustments {
                    Text("No adjustments applied")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    private func adjustmentRows(for adjustments: ImageAdjustments, color: Color) -> some View {
        if adjustments.brightness != 0 {
            InfoRow(label: "Brightness", value: formatAdjustment(adjustments.brightness), valueColor: color)
        }
        if adjustments.contrast != 0 {
            InfoRow(label: "Contrast", value: formatAdjustment(adjustments.contrast), valueColor: color)
        }
        if adjustments.saturation != 0 {
            InfoRow(label: "Saturation", value: formatAdjustment(adjustments.saturation), valueColor: color)
        }
        if adjustments.exposure != 0 {
            InfoRow(label: "Exposure", value: formatAdjustment(adjustments.exposure), valueColor: color)
        }
        if adjustments.highlights != 0 {
            InfoRow(label: "Highlights", value: formatAdjustment(adjustments.highlights), valueColor: color)
        }
        if adjustments.shadows != 0 {
            InfoRow(label: "Shadows", value: formatAdjustment(adjustments.shadows), valueColor: color)
        }
        if adjustments.warmth != 0 {
            InfoRow(label: "Warmth", value: formatAdjustment(adjustments.warmth), valueColor: color)
        }
        if adjustments.tint != 0 {
            InfoRow(label: "Tint", value: formatAdjustment(adjustments.tint), valueColor: color)
        }
    }
    
    private var sessionStatsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session Stats")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Duration", value: editSession.sessionStats.formattedSessionDuration)
                InfoRow(label: "Operations", value: "\(editSession.sessionStats.operationCount)")
                InfoRow(label: "Exports", value: "\(editSession.sessionStats.exportCount)")
            }
        }
    }
    
    private var editHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent History")
                .font(.headline)
            
            if editSession.editHistory.isEmpty {
                Text("No operations")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(editSession.editHistory.suffix(5).reversed(), id: \.id) { operation in
                        HStack {
                            Image(systemName: operation.type.iconName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 12)
                            
                            Text(operation.description)
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(formatTime(operation.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private func formatRect(_ rect: CGRect) -> String {
        return "(\(Int(rect.origin.x)), \(Int(rect.origin.y))) \(Int(rect.width))×\(Int(rect.height))"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatAdjustment(_ value: Float) -> String {
        let sign = value >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", value))"
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    let valueColor: Color
    
    init(label: String, value: String, valueColor: Color = .primary) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(valueColor)
        }
    }
}

extension EditOperationType {
    var iconName: String {
        switch self {
        case .imageLoad:
            return "photo"
        case .adjustmentChange:
            return "slider.horizontal.3"
        case .filterApplication:
            return "camera.filters"
        case .reset:
            return "arrow.counterclockwise"
        }
    }
}