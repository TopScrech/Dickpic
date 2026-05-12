import SwiftUI

struct PhotoLibrarySettingsButton: View {
    var body: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}
