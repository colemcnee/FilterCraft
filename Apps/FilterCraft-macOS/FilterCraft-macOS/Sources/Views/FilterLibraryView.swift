import SwiftUI
import FilterCraftCore

struct FilterLibraryView: View {
    @ObservedObject var editSession: EditSession
    @Binding var selectedFilterType: FilterType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Filters")
                    .font(.headline)
                
                Spacer()
                
                if editSession.appliedFilter != nil {
                    Text(editSession.appliedFilter?.filterType.displayName ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(FilterType.allCases, id: \.self) { filterType in
                        FilterButton(
                            filterType: filterType,
                            isSelected: selectedFilterType == filterType,
                            action: {
                                selectedFilterType = filterType
                                editSession.applyFilter(filterType, intensity: filterType.defaultIntensity)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}