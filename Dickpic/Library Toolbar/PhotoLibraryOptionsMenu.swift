import SwiftUI

struct PhotoLibraryOptionsMenu: View {
    var body: some View {
        Menu {
            PhotoLibraryBlurToggleButton()
            PhotoLibraryResetButton()
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
