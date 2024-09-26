import SwiftUI

struct SettingsView: View {
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        List {
#if DEBUG
            Button("Show intro") {
                fullScreenCover = true
            }
#endif
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    @Previewable @State var fullScreenCover = false
    
    SettingsView($fullScreenCover)
}
