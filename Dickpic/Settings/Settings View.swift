import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var storage: SettingsStorage
    
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        List {
            Toggle(isOn: $storage.analyzeConcurrently) {
                Text("Analyze concurrently")
                Text("Speeds up the analysis")
            }
            
            Toggle(isOn: $storage.downloadOriginals) {
                Text("Download original images")
                Text("In case the images are offloaded to iCloud")
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
        .environmentObject(SettingsStorage())
}
