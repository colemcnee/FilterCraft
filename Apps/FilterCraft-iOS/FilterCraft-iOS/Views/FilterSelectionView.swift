import FilterCraftCore
import SwiftUI

struct FilterSelectionView: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Filters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if editSession.appliedFilter != nil {
                    Text(editSession.appliedFilter?.description ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases) { filterType in
                        FilterButton(
                            filterType: filterType,
                            isSelected: editSession.appliedFilter?.filterType == filterType || editSession.pendingFilter == filterType,
                            isProcessing: editSession.processingState != .idle && editSession.processingState != .completed
                        ) {
                            editSession.applyFilter(filterType, intensity: filterType.defaultIntensity)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FilterButton: View {
    let filterType: FilterType
    let isSelected: Bool
    let isProcessing: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? .blue : Color(.systemGray5))
                        .frame(width: 60, height: 60)
                    
                    if isProcessing && isSelected {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: filterType.iconName)
                            .font(.title2)
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                }
            }
            .buttonStyle(.plain)
            
            Text(filterType.displayName)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}
