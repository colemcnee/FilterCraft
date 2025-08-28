import FilterCraftCore
import SwiftUI

@main
struct FilterCraftApp: App {
    @StateObject private var editSession = EditSession()
    
    var body: some Scene {
        WindowGroup {
            ContentView(editSession: editSession)
                .frame(minWidth: 1000, minHeight: 700)
                .navigationTitle("FilterCraft")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            FilterCraftCommands(editSession: editSession)
        }
    }
}
