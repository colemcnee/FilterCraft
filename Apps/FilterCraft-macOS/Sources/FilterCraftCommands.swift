import SwiftUI
import FilterCraftCore

struct FilterCraftCommands: Commands {
    var body: some Commands {
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
        
        // Edit Menu
        CommandGroup(after: .undoRedo) {
            Divider()
            
            Button("Reset All Edits") {
                NotificationCenter.default.post(name: .resetEdits, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            
            Button("Copy Image") {
                NotificationCenter.default.post(name: .copyImage, object: nil)
            }
            .keyboardShortcut("c", modifiers: .command)
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

struct FilterMenuCommands: View {
    var body: some View {
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