import SwiftUI

struct PhotoLibraryToolbarModifier: ViewModifier {
    @Binding var fullScreenCover: Bool
    @Binding var unblurTrigger: Bool
    
    func body(content: Content) -> some View {
        content
            .toolbar {
#if os(macOS)
                PhotoLibraryAnalyzeFolderButton()
                PhotoLibraryOptionsMenu(unblurTrigger: $unblurTrigger)
                PhotoLibrarySettingsButton($fullScreenCover)
#else
                ToolbarItem(placement: .topBarLeading) {
                    PhotoLibraryOptionsMenu(unblurTrigger: $unblurTrigger)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    PhotoLibrarySettingsButton($fullScreenCover)
                }
#endif
            }
    }
}

extension View {
    func photoLibraryToolbar(fullScreenCover: Binding<Bool>, unblurTrigger: Binding<Bool>) -> some View {
        modifier(
            PhotoLibraryToolbarModifier(fullScreenCover: fullScreenCover, unblurTrigger: unblurTrigger)
        )
    }
}
