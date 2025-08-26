import SwiftUI
import FilterCraftCore

struct ContentView: View {
    @State private var selectedFilter: FilterType = .none
    @State private var imageAdjustments = FilterCraftCore.defaultAdjustments()
    @State private var appliedFilter: AppliedFilter?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    filterSelectionSection
                    selectedFilterInfoSection
                    adjustmentsTestingSection
                    filterCategoriesSection
                    appliedFilterSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("FilterCraft Core Test")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("FilterCraft Core")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Multi-Platform Photo Filtering Framework")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Version \(FilterCraftCore.version)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
        }
    }
    
    private var filterSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Filters")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(FilterType.allCases) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter
                        ) {
                            selectedFilter = filter
                            appliedFilter = FilterCraftCore.createAppliedFilter(type: filter)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var selectedFilterInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected Filter Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InfoRow(label: "Name", value: selectedFilter.displayName)
                InfoRow(label: "Category", value: selectedFilter.category.displayName)
                InfoRow(label: "Default Intensity", value: "\(Int(selectedFilter.defaultIntensity * 100))%")
                InfoRow(label: "Core Image Filters", value: selectedFilter.coreImageFilters.isEmpty ? "None" : selectedFilter.coreImageFilters.joined(separator: ", "))
            }
            .padding(16)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var adjustmentsTestingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Image Adjustments Test")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Reset") {
                    imageAdjustments.reset()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .clipShape(Capsule())
            }
            
            VStack(spacing: 8) {
                ForEach([AdjustmentType.brightness, .contrast, .saturation, .exposure], id: \.self) { adjustmentType in
                    AdjustmentSlider(
                        adjustmentType: adjustmentType,
                        value: Binding(
                            get: { imageAdjustments.value(for: adjustmentType) },
                            set: { imageAdjustments.setValue($0, for: adjustmentType) }
                        )
                    )
                }
            }
            
            HStack {
                Text("Has Adjustments:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(imageAdjustments.hasAdjustments ? "Yes" : "No")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(imageAdjustments.hasAdjustments ? .green : .red)
            }
            .padding(.top, 8)
        }
    }
    
    private var filterCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter Categories")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(FilterCategory.allCases, id: \.self) { category in
                    CategoryCard(
                        category: category,
                        filterCount: FilterCraftCore.filters(for: category).count
                    )
                }
            }
        }
    }
    
    private var appliedFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Applied Filter")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let appliedFilter = appliedFilter {
                VStack(spacing: 12) {
                    InfoRow(label: "Description", value: appliedFilter.description)
                    InfoRow(label: "Is Effective", value: appliedFilter.isEffective ? "Yes" : "No")
                    InfoRow(label: "Applied At", value: DateFormatter.localizedString(from: appliedFilter.appliedAt, dateStyle: .none, timeStyle: .medium))
                    
                    if appliedFilter.filterType != .none {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Intensity: \(Int(appliedFilter.intensity * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(
                                value: Binding(
                                    get: { appliedFilter.intensity },
                                    set: { self.appliedFilter = appliedFilter.withIntensity($0) }
                                ),
                                in: 0...1,
                                step: 0.1
                            )
                        }
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text("No filter applied")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct FilterButton: View {
    let filter: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: filter.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct AdjustmentSlider: View {
    let adjustmentType: AdjustmentType
    @Binding var value: Float
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: adjustmentType.iconName)
                    .font(.caption)
                    .frame(width: 16)
                
                Text(adjustmentType.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(String(format: "%.1f", value))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Float($0) }
                ),
                in: Double(adjustmentType.minValue)...Double(adjustmentType.maxValue),
                step: 0.1
            )
            .tint(.blue)
        }
    }
}

struct CategoryCard: View {
    let category: FilterCategory
    let filterCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
            
            Text("\(filterCount) filters")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}