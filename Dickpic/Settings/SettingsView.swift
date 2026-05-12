import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ValueStore
    
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        List {
            Toggle(isOn: $store.downloadOriginals) {
                Text("Download original images")
                Text("In case the images are offloaded to iCloud")
            }
            
            Toggle("Analyze videos", isOn: $store.analyzeVideos)
            Toggle("Analyze recent items first", isOn: $store.analyzeNewestFirst)
            
            Toggle(isOn: $store.analyzeConcurrently) {
                Text("Analyze concurrently")
                Text("Speeds up the analysis")
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            NavigationLink {
                DebugSettings($fullScreenCover)
            } label: {
                Label("Debug", systemImage: "hammer")
            }
        }
    }
}

#Preview {
    @Previewable @State var fullScreenCover = false
    
    SettingsView($fullScreenCover)
        .environmentObject(ValueStore())
}
