import SwiftUI

struct PhotoLibraryBlurToggleButton: View {
    @EnvironmentObject private var store: ValueStore
    
    private var title: LocalizedStringKey {
        store.blurSensitiveMedia ? "Unblur All" : "Blur All"
    }
    
    private var systemImage: String {
        store.blurSensitiveMedia ? "eye" : "eye.slash"
    }
    
    var body: some View {
        Button(title, systemImage: systemImage, action: toggleBlur)
    }
    
    private func toggleBlur() {
        store.blurSensitiveMedia.toggle()
    }
}
