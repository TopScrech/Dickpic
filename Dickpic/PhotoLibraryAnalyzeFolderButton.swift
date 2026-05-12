import ScrechKit

#if os(macOS)
struct PhotoLibraryAnalyzeFolderButton: View {
    @Environment(PhotoLibraryVM.self) private var vm
    @EnvironmentObject private var store: ValueStore
    
    var body: some View {
        SFButton("folder", action: analyzeFolder)
    }
    
    private func analyzeFolder() {
        vm.analyzeFolder(store.analyzeConcurrently)
    }
}
#endif
