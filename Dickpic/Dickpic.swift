import SwiftUI

@main
struct Dickpic: App {
    @StateObject private var store = ValueStore()
    
    var body: some Scene {
        WindowGroup {
            AppContainer()
                .environmentObject(store)
        }
    }
}
