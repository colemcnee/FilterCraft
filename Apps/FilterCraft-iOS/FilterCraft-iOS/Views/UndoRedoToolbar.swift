import SwiftUI
import FilterCraftCore

/// iOS toolbar component providing undo/redo functionality
///
/// This toolbar integrates with the EditSession's command history system
/// to provide intuitive undo/redo controls with proper accessibility support.
struct UndoRedoToolbar: View {
    @ObservedObject var editSession: EditSession
    
    // Visual configuration
    private let buttonSize: CGFloat = 44
    private let iconSize: CGFloat = 20
    
    var body: some View {
        HStack(spacing: 20) {
            // Undo button
            undoButton
            
            // Separator
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1, height: 20)
            
            // Redo button
            redoButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
        .opacity(editSession.originalImage != nil ? 1.0 : 0.0)
        .disabled(editSession.originalImage == nil)
        .animation(.easeInOut(duration: 0.2), value: editSession.originalImage != nil)
    }
    
    private var undoButton: some View {
        Button {
            Task {
                await editSession.undo()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(editSession.commandHistory.canUndo ? .primary : .secondary)
                
                if let description = editSession.commandHistory.undoDescription {
                    Text("Undo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: buttonSize, minHeight: buttonSize)
            .contentShape(Rectangle())
        }
        .disabled(!editSession.commandHistory.canUndo)
        .accessibilityLabel("Undo")
        .accessibilityHint(editSession.commandHistory.undoDescription.map { "Undo \($0)" } ?? "No actions to undo")
        .accessibilityAction(.default) {
            Task { await editSession.undo() }
        }
        .buttonStyle(ToolbarButtonStyle())
    }
    
    private var redoButton: some View {
        Button {
            Task {
                await editSession.redo()
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: iconSize, weight: .medium))
                    .foregroundColor(editSession.commandHistory.canRedo ? .primary : .secondary)
                
                if let description = editSession.commandHistory.redoDescription {
                    Text("Redo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(minWidth: buttonSize, minHeight: buttonSize)
            .contentShape(Rectangle())
        }
        .disabled(!editSession.commandHistory.canRedo)
        .accessibilityLabel("Redo")
        .accessibilityHint(editSession.commandHistory.redoDescription.map { "Redo \($0)" } ?? "No actions to redo")
        .accessibilityAction(.default) {
            Task { await editSession.redo() }
        }
        .buttonStyle(ToolbarButtonStyle())
    }
}

/// Custom button style for toolbar buttons
struct ToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Compact version of the undo/redo toolbar for constrained layouts
struct CompactUndoRedoToolbar: View {
    @ObservedObject var editSession: EditSession
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task { await editSession.undo() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(editSession.commandHistory.canUndo ? .primary : .secondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(!editSession.commandHistory.canUndo)
            .accessibilityLabel("Undo")
            .accessibilityHint(editSession.commandHistory.undoDescription.map { "Undo \($0)" } ?? "No actions to undo")
            
            Button {
                Task { await editSession.redo() }
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(editSession.commandHistory.canRedo ? .primary : .secondary)
                    .frame(width: 32, height: 32)
            }
            .disabled(!editSession.commandHistory.canRedo)
            .accessibilityLabel("Redo")
            .accessibilityHint(editSession.commandHistory.redoDescription.map { "Redo \($0)" } ?? "No actions to redo")
        }
    }
}

/// History viewer component showing edit timeline
struct EditHistoryView: View {
    @ObservedObject var editSession: EditSession
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Edit History")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            if isExpanded {
                VStack(spacing: 0) {
                    // Statistics
                    historyStatistics
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Memory usage
                    memoryUsageIndicator
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Actions
                    historyActions
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private var historyStatistics: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Commands")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(editSession.commandHistory.totalCommands)")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Position")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(editSession.commandHistory.currentPosition)")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Undo/Redo")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Text("\(editSession.commandHistory.statistics.undoOperations)")
                    Text("/")
                        .foregroundColor(.secondary)
                    Text("\(editSession.commandHistory.statistics.redoOperations)")
                }
                .font(.headline)
            }
        }
    }
    
    private var memoryUsageIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Memory Usage")
                .font(.caption)
                .foregroundColor(.secondary)
            
            let memoryMB = Double(editSession.commandHistory.memoryUsage) / 1_000_000.0
            let maxMemoryMB = 100.0 // 100MB limit
            let usagePercent = min(memoryMB / maxMemoryMB, 1.0)
            
            HStack {
                Text(String(format: "%.1f MB", memoryMB))
                    .font(.caption)
                    .monospacedDigit()
                
                Spacer()
                
                Text(String(format: "%.0f%%", usagePercent * 100))
                    .font(.caption)
                    .foregroundColor(usagePercent > 0.8 ? .red : .secondary)
            }
            
            ProgressView(value: usagePercent)
                .tint(usagePercent > 0.8 ? .red : .blue)
                .scaleEffect(y: 0.5)
        }
    }
    
    private var historyActions: some View {
        HStack(spacing: 12) {
            Button("Clear History") {
                editSession.clearCommandHistory()
            }
            .font(.caption)
            .foregroundColor(.red)
            .disabled(editSession.commandHistory.totalCommands == 0)
            
            Spacer()
            
            Button("Cleanup Memory") {
                editSession.commandHistory.performMemoryCleanup()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        UndoRedoToolbar(editSession: EditSession())
        CompactUndoRedoToolbar(editSession: EditSession())
        EditHistoryView(editSession: EditSession())
    }
    .padding()
}