import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: ValueStore
    
    private var aspectRatioTitle: LocalizedStringKey {
        store.squarePhotoGrid ? "Aspect Ratio Grid" : "Square Photo Grid"
    }
    
    var body: some View {
        List {
            Section("Analyzing") {
                Toggle(isOn: $store.downloadOriginals) {
                    Text("Download original images")
                    Text("In case the images are offloaded to iCloud")
                }
                
                Toggle("Analyze videos", isOn: $store.analyzeVideos)
                Toggle("Recent items first", isOn: $store.analyzeNewestFirst)
                
                Toggle(isOn: $store.analyzeConcurrently) {
                    Text("Multi-threading")
                    Text("Speeds up the analysis")
                }
            }
            
            Section("Layout") {
                Toggle(aspectRatioTitle, isOn: $store.squarePhotoGrid)
            }
        }
        .navigationTitle("Settings")
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink {
                DebugSettings()
            } label: {
                Label("Debug", systemImage: "hammer")
            }
        }
    }
}

//#Preview {
//    SettingsView()
//        .environmentObject(ValueStore())
//}
