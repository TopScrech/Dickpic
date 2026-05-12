import SwiftUI

struct PhotoLibraryGridToggleButton: View {
    @EnvironmentObject private var store: ValueStore
    
    private var title: LocalizedStringKey {
        store.squarePhotoGrid ? "Aspect Ratio Grid" : "Square Photo Grid"
    }
    
    private var systemImage: String {
        store.squarePhotoGrid ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward"
    }
    
    var body: some View {
        Button(title, systemImage: systemImage, action: toggleGridMode)
    }
    
    private func toggleGridMode() {
        store.squarePhotoGrid.toggle()
    }
}
