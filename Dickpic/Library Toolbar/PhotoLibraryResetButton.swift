import SwiftUI

struct PhotoLibraryResetButton: View {
    @Environment(PhotoLibraryVM.self) private var vm
    
    var body: some View {
        Button("Reset", systemImage: "xmark", action: reset)
    }
    
    private func reset() {
        vm.resetResults()
    }
}
