import SwiftUI

struct PhotoLibrarySettingsButton: View {
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        NavigationLink {
            SettingsView($fullScreenCover)
        } label: {
            Label("Settings", systemImage: "gear")
        }
    }
}
