import SwiftUI

@main
struct Dickpic: App {
    @StateObject private var storage = ValueStore()
    
    var body: some Scene {
        WindowGroup {
            AppContainer()
                .environmentObject(storage)
        }
    }
}
