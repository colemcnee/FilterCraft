import SwiftUI
import FilterCraftCore

struct AdjustmentControlsView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Adjustments")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if editSession.userAdjustments.hasAdjustments {
                    Button("Reset") {
                        editSession.updateUserAdjustments(ImageAdjustments())
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
            }
            
            // Show filter base adjustments if any filter is applied
            if editSession.baseAdjustments.hasAdjustments {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("From Filter: \(editSession.appliedFilter?.filterType.displayName ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("(Base adjustments)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(AdjustmentType.allCases.filter { editSession.baseAdjustments.value(for: $0) != 0 }) { adjustmentType in
                            BaseAdjustmentRow(
                                adjustmentType: adjustmentType,
                                value: editSession.baseAdjustments.value(for: adjustmentType)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // User adjustments section
            VStack(alignment: .leading, spacing: 8) {
                if editSession.baseAdjustments.hasAdjustments {
                    HStack {
                        Text("Manual Adjustments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("(Added to filter)")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                VStack(spacing: 12) {
                    ForEach(AdjustmentType.allCases) { adjustmentType in
                        AdjustmentSliderRow(
                            adjustmentType: adjustmentType,
                            value: Binding(
                                get: { editSession.userAdjustments.value(for: adjustmentType) },
                                set: { newValue in
                                    var newAdjustments = editSession.userAdjustments
                                    newAdjustments.setValue(newValue, for: adjustmentType)
                                    editSession.updateUserAdjustments(newAdjustments)
                                }
                            )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct BaseAdjustmentRow: View {
    let adjustmentType: AdjustmentType
    let value: Float
    
    var body: some View {
        HStack {
            Image(systemName: adjustmentType.iconName)
                .font(.caption)
                .frame(width: 20)
                .foregroundColor(.blue)
            
            Text(adjustmentType.displayName)
                .font(.caption)
                .foregroundColor(.blue)
            
            Spacer()
            
            Text(String(format: "%.2f", value))
                .font(.caption)
                .foregroundColor(.blue)
                .monospacedDigit()
        }
    }
}

struct AdjustmentSliderRow: View {
    let adjustmentType: AdjustmentType
    @Binding var value: Float
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: adjustmentType.iconName)
                    .font(.caption)
                    .frame(width: 20)
                
                Text(adjustmentType.displayName)
                    .font(.caption)
                
                Spacer()
                
                Text(String(format: "%.2f", value))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(minWidth: 40)
                
                if value != adjustmentType.defaultValue {
                    Button(action: { value = adjustmentType.defaultValue }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                }
            }
            
            Slider(
                value: $value,
                in: adjustmentType.minValue...adjustmentType.maxValue
            ) {
                Text(adjustmentType.displayName)
            }
            .tint(value != adjustmentType.defaultValue ? .blue : .gray)
        }
    }
}