import FilterCraftCore
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var isInCropMode = false
}

@main
struct FilterCraftApp: App {
    @StateObject private var editSession = EditSession()
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView(editSession: editSession, appState: appState)
                .frame(minWidth: 1000, minHeight: 700)
                .navigationTitle("FilterCraft")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            FilterCraftCommands(editSession: editSession, isInCropMode: $appState.isInCropMode)
        }
    }
}
