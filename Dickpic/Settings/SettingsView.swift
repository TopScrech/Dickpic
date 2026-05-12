import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ValueStore
    
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
    }
}

#Preview {
    SettingsView()
        .environmentObject(ValueStore())
}
