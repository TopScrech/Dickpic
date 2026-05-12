import SwiftUI

struct PhotoLibraryToolbarModifier: ViewModifier {
    @Binding var fullScreenCover: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
#if os(macOS)
                PhotoLibraryAnalyzeFolderButton()
                PhotoLibraryOptionsMenu()
                PhotoLibrarySettingsButton($fullScreenCover)
#else
                ToolbarItem(placement: .topBarLeading) {
                    PhotoLibraryOptionsMenu()
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotoLibrarySettingsButton($fullScreenCover)
                }
#endif
            }
    }
}

extension View {
    func photoLibraryToolbar(fullScreenCover: Binding<Bool>) -> some View {
        modifier(
            PhotoLibraryToolbarModifier(fullScreenCover: fullScreenCover)
        )
    }
}
