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
            
            Toggle(isOn: $store.analyzeVideos) {
                Text("Analyze videos")
            }
            
            Toggle(isOn: $store.analyzeConcurrently) {
                Text("Analyze concurrently")
                Text("Speeds up the analysis")
            }
#if DEBUG
            Section("Debug") {
                Button("Show intro") {
                    fullScreenCover = true
                }
                .foregroundStyle(.foreground)
            }
#endif
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    @Previewable @State var fullScreenCover = false
    
    SettingsView($fullScreenCover)
        .environmentObject(ValueStore())
}
