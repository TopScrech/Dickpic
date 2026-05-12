import SwiftUI

struct PhotoLibraryOptionsMenu: View {
    @Binding var unblurTrigger: Bool
    
    var body: some View {
        Menu {
            PhotoLibraryUnblurAllButton(unblurTrigger: $unblurTrigger)
            
            PhotoLibraryResetButton()
        } label: {
            Image(systemName: "ellipsis")
        }
    }
}
