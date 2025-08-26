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
            
            VStack(alignment: .leading, spacing: 4) {
                if editSession.adjustments.hasAdjustments {
                    if editSession.adjustments.brightness != 0 {
                        InfoRow(label: "Brightness", value: formatAdjustment(editSession.adjustments.brightness))
                    }
                    if editSession.adjustments.contrast != 0 {
                        InfoRow(label: "Contrast", value: formatAdjustment(editSession.adjustments.contrast))
                    }
                    if editSession.adjustments.saturation != 0 {
                        InfoRow(label: "Saturation", value: formatAdjustment(editSession.adjustments.saturation))
                    }
                    if editSession.adjustments.exposure != 0 {
                        InfoRow(label: "Exposure", value: formatAdjustment(editSession.adjustments.exposure))
                    }
                    if editSession.adjustments.highlights != 0 {
                        InfoRow(label: "Highlights", value: formatAdjustment(editSession.adjustments.highlights))
                    }
                    if editSession.adjustments.shadows != 0 {
                        InfoRow(label: "Shadows", value: formatAdjustment(editSession.adjustments.shadows))
                    }
                    if editSession.adjustments.warmth != 0 {
                        InfoRow(label: "Warmth", value: formatAdjustment(editSession.adjustments.warmth))
                    }
                    if editSession.adjustments.tint != 0 {
                        InfoRow(label: "Tint", value: formatAdjustment(editSession.adjustments.tint))
                    }
                } else {
                    Text("No adjustments applied")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
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
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .monospaced))
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