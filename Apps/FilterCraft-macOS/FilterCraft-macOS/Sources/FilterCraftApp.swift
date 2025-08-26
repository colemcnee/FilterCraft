import SwiftUI

@main
struct FilterCraftApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .navigationTitle("FilterCraft")
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            FilterCraftCommands()
        }
    }
}