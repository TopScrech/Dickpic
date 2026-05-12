import SwiftUI

struct PhotoLibraryToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
#if os(macOS)
                PhotoLibraryAnalyzeFolderButton()
                PhotoLibraryOptionsMenu()
                PhotoLibrarySettingsButton()
#else
                ToolbarItem(placement: .topBarLeading) {
                    PhotoLibraryOptionsMenu()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotoLibrarySettingsButton()
                }
#endif
            }
    }
}

extension View {
    func photoLibraryToolbar() -> some View {
        modifier(PhotoLibraryToolbarModifier())
    }
}
