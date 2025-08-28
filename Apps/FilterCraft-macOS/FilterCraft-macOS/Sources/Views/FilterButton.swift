import FilterCraftCore
import SwiftUI

struct FilterButton: View {
    let filterType: FilterType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: filterType.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 32, height: 32)
                
                Text(filterType.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 70)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.blue : Color.secondary.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}
