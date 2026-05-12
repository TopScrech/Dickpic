import SwiftUI

struct PhotoLibraryUnblurAllButton: View {
    @Binding var unblurTrigger: Bool
    
    var body: some View {
        Button("Unblur All", systemImage: "eye", action: unblurAll)
    }
    
    private func unblurAll() {
        unblurTrigger.toggle()
    }
}
