import SwiftUI

struct PhotoLibraryOptionsMenu: View {
    var body: some View {
        Menu {
            PhotoLibraryGridToggleButton()
            PhotoLibraryBlurToggleButton()
            PhotoLibraryResetButton()
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
