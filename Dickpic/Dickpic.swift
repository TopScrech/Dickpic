import SwiftUI

@main
struct Dickpic: App {
    @StateObject private var storage = SettingsStorage()
    
    var body: some Scene {
        WindowGroup {
            AppContainer()
                .environmentObject(storage)
        }
    }
}
