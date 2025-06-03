import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: ValueStore
    
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        List {
            Toggle(isOn: $storage.analyzeVideos) {
                Text("Analyze videos")
            }
            
            // Doesn't work
            //            Toggle(isOn: $storage.includeHiddenAssets) {
            //                Text("Include hidden assets")
            //            }
            
            Toggle(isOn: $storage.downloadOriginals) {
                Text("Download original images")
                Text("In case the images are offloaded to iCloud")
            }
            
            Toggle(isOn: $storage.analyzeConcurrently) {
                Text("Analyze concurrently")
                Text("Speeds up the analysis")
            }
#if DEBUG
            Section {
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
