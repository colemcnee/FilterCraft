import SwiftUI
import FilterCraftCore

internal struct FilterCraftCommands: Commands {
    @ObservedObject var editSession: EditSession
    
    internal var body: some Commands {
        // File Menu
        CommandGroup(replacing: .newItem) {
            Button("Open Image...") {
                NotificationCenter.default.post(name: .openImage, object: nil)
            }
            .keyboardShortcut("o", modifiers: .command)
            
            Button("Save Image...") {
                NotificationCenter.default.post(name: .saveImage, object: nil)
            }
            .keyboardShortcut("s", modifiers: .command)
            
            Divider()
            
            Button("Export As...") {
                NotificationCenter.default.post(name: .exportImage, object: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
        
        // Edit Menu - Replace the default undo/redo with our command-based system
        CommandGroup(replacing: .undoRedo) {
            Button(editSession.commandHistory.undoDescription.map { "Undo \($0)" } ?? "Undo") {
                Task { await editSession.undo() }
            }
            .keyboardShortcut("z", modifiers: .command)
            .disabled(!editSession.commandHistory.canUndo)
            
            Button(editSession.commandHistory.redoDescription.map { "Redo \($0)" } ?? "Redo") {
                Task { await editSession.redo() }
            }
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(!editSession.commandHistory.canRedo)
        }
        
        CommandGroup(after: .undoRedo) {
            Divider()
            
            Button("Reset All Edits") {
                Task { await editSession.resetToOriginal() }
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(editSession.originalImage == nil || !editSession.hasEdits)
            
            Button("Reset Adjustments") {
                Task { await editSession.resetAdjustments() }
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(editSession.originalImage == nil || (!editSession.userAdjustments.hasAdjustments && !editSession.baseAdjustments.hasAdjustments))
            
            Button("Reset Filter") {
                Task { await editSession.resetFilter() }
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .disabled(editSession.appliedFilter == nil)
            
            Button("Smart Reset") {
                Task { await editSession.smartReset() }
            }
            .keyboardShortcut("r", modifiers: [.command, .control])
            .disabled(editSession.originalImage == nil || !editSession.hasEdits)
            
            Divider()
            
            Button("Copy Image") {
                NotificationCenter.default.post(name: .copyImage, object: nil)
            }
            .keyboardShortcut("c", modifiers: .command)
            .disabled(editSession.originalImage == nil)
            
            Divider()
            
            Button("Clear Edit History") {
                editSession.clearCommandHistory()
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            .disabled(editSession.commandHistory.totalCommands == 0)
        }
        
        // View Menu
        CommandMenu("View") {
            Button("Toggle Inspector") {
                NotificationCenter.default.post(name: .toggleInspector, object: nil)
            }
            .keyboardShortcut("i", modifiers: [.command, .option])
            
            Button("Toggle Before/After Comparison") {
                NotificationCenter.default.post(name: .toggleBeforeAfter, object: nil)
            }
            .keyboardShortcut("b", modifiers: .command)
            
            Divider()
            
            Button("Zoom In") {
                NotificationCenter.default.post(name: .zoomIn, object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)
            
            Button("Zoom Out") {
                NotificationCenter.default.post(name: .zoomOut, object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)
            
            Button("Actual Size") {
                NotificationCenter.default.post(name: .zoomActualSize, object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)
            
            Button("Fit to Window") {
                NotificationCenter.default.post(name: .zoomToFit, object: nil)
            }
            .keyboardShortcut("9", modifiers: .command)
        }
        
        // Filter Menu
        CommandMenu("Filter") {
            FilterMenuCommands()
        }
        
        // History Menu - Advanced history management
        CommandMenu("History") {
            EditHistoryMenuCommands(editSession: editSession)
        }
        
        // Window Menu
        CommandGroup(replacing: .windowSize) {
            Button("Minimize") {
                NSApp.keyWindow?.miniaturize(nil)
            }
            .keyboardShortcut("m", modifiers: .command)
        }
        
        // Help Menu
        CommandGroup(replacing: .help) {
            Button("FilterCraft Help") {
                NotificationCenter.default.post(name: .showHelp, object: nil)
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}

internal struct FilterMenuCommands: View {
    internal var body: some View {
        Group {
            Button("No Filter") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.none)
            }
            .keyboardShortcut("0", modifiers: [.command, .option])
            
            Divider()
            
            Button("Vintage") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.vintage)
            }
            .keyboardShortcut("1", modifiers: [.command, .option])
            
            Button("Black & White") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.blackAndWhite)
            }
            .keyboardShortcut("2", modifiers: [.command, .option])
            
            Button("Vibrant") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.vibrant)
            }
            .keyboardShortcut("3", modifiers: [.command, .option])
            
            Button("Sepia") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.sepia)
            }
            .keyboardShortcut("4", modifiers: [.command, .option])
            
            Button("Cool") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.cool)
            }
            .keyboardShortcut("5", modifiers: [.command, .option])
            
            Button("Warm") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.warm)
            }
            .keyboardShortcut("6", modifiers: [.command, .option])
            
            Button("Dramatic") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.dramatic)
            }
            .keyboardShortcut("7", modifiers: [.command, .option])
            
            Button("Soft") {
                NotificationCenter.default.post(name: .applyFilter, object: FilterType.soft)
            }
            .keyboardShortcut("8", modifiers: [.command, .option])
        }
    }
}

/// Edit History menu commands for advanced history management
internal struct EditHistoryMenuCommands: View {
    @ObservedObject var editSession: EditSession
    
    internal var body: some View {
        Group {
            // Navigation
            Button("Go to Beginning") {
                Task { await goToHistoryPosition(0) }
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
            .disabled(editSession.commandHistory.currentPosition == 0)
            
            Button("Go to End") {
                Task { await goToHistoryPosition(editSession.commandHistory.totalCommands) }
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])
            .disabled(editSession.commandHistory.currentPosition == editSession.commandHistory.totalCommands)
            
            Divider()
            
            // Batch operations
            Button("Undo All") {
                Task { await undoAll() }
            }
            .keyboardShortcut("z", modifiers: [.command, .option])
            .disabled(!editSession.commandHistory.canUndo)
            
            Button("Redo All") {
                Task { await redoAll() }
            }
            .keyboardShortcut("z", modifiers: [.command, .option, .shift])
            .disabled(!editSession.commandHistory.canRedo)
            
            Divider()
            
            // Memory management
            Button("Optimize Memory") {
                editSession.commandHistory.performMemoryCleanup()
            }
            .keyboardShortcut("m", modifiers: [.command, .option])
            
            Button("Show Memory Usage") {
                showMemoryUsageAlert()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            
            Divider()
            
            // Statistics
            Button("Show History Statistics") {
                showHistoryStatistics()
            }
            .keyboardShortcut("h", modifiers: [.command, .option])
            
            // Advanced options
            Menu("Advanced") {
                Button("Export History") {
                    exportHistory()
                }
                
                Button("Clear Statistics") {
                    clearStatistics()
                }
                .foregroundColor(.red)
                
                Divider()
                
                Toggle("Auto Memory Cleanup", isOn: .constant(true))
                    .disabled(true) // Would be configurable in full implementation
            }
        }
    }
    
    // MARK: - History Navigation
    
    private func goToHistoryPosition(_ position: Int) async {
        let currentPosition = editSession.commandHistory.currentPosition
        let targetPosition = max(0, min(position, editSession.commandHistory.totalCommands))
        
        if targetPosition < currentPosition {
            // Undo to target position
            for _ in 0..<(currentPosition - targetPosition) {
                await editSession.undo()
            }
        } else if targetPosition > currentPosition {
            // Redo to target position
            for _ in 0..<(targetPosition - currentPosition) {
                await editSession.redo()
            }
        }
    }
    
    private func undoAll() async {
        while editSession.commandHistory.canUndo {
            await editSession.undo()
        }
    }
    
    private func redoAll() async {
        while editSession.commandHistory.canRedo {
            await editSession.redo()
        }
    }
    
    // MARK: - Information Display
    
    private func showMemoryUsageAlert() {
        let memoryMB = Double(editSession.commandHistory.memoryUsage) / 1_000_000.0
        let commandCount = editSession.commandHistory.totalCommands
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Edit History Memory Usage"
            alert.informativeText = """
                Current memory usage: \(String(format: "%.1f MB", memoryMB))
                Command count: \(commandCount)
                Current position: \(editSession.commandHistory.currentPosition)
                """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    private func showHistoryStatistics() {
        let stats = editSession.commandHistory.statistics
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Edit History Statistics"
            alert.informativeText = """
                Total commands: \(stats.totalCommands)
                Undo operations: \(stats.undoOperations)
                Redo operations: \(stats.redoOperations)
                Pruned commands: \(stats.prunedCommands)
                Undo/Redo ratio: \(String(format: "%.2f", stats.undoRedoRatio))
                Commands per minute: \(String(format: "%.1f", stats.averageCommandsPerMinute))
                """
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    // MARK: - Advanced Operations
    
    private func exportHistory() {
        // Would implement history export functionality
        let alert = NSAlert()
        alert.messageText = "Export History"
        alert.informativeText = "History export functionality would be implemented here."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func clearStatistics() {
        // Would reset statistics while keeping history
        let alert = NSAlert()
        alert.messageText = "Clear Statistics"
        alert.informativeText = "This would clear usage statistics while preserving the edit history."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            // Implementation would clear statistics here
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openImage = Notification.Name("openImage")
    static let saveImage = Notification.Name("saveImage")
    static let exportImage = Notification.Name("exportImage")
    static let resetEdits = Notification.Name("resetEdits")
    static let copyImage = Notification.Name("copyImage")
    static let toggleInspector = Notification.Name("toggleInspector")
    static let toggleBeforeAfter = Notification.Name("toggleBeforeAfter")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let zoomActualSize = Notification.Name("zoomActualSize")
    static let zoomToFit = Notification.Name("zoomToFit")
    static let applyFilter = Notification.Name("applyFilter")
    static let showHelp = Notification.Name("showHelp")
}