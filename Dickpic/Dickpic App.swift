import SwiftUI

@main
struct DickpicApp: App {
    @StateObject private var storage = SettingsStorage()
    
    var body: some Scene {
        WindowGroup {
            AppContainer()
                .environmentObject(storage)
        }
    }
}
