import ScrechKit

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    private static let initialColumns = 3
    
#if os(macOS)
    private let gridItemSize = 160.0
#else
    private let gridItemSize = 120.0
#endif
    
    private var gridColumns: [GridItem] {[
        GridItem(.adaptive(minimum: gridItemSize, maximum: gridItemSize))
    ]}
    
    var body: some View {
        VStack {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(vm.sensitiveAssets) { asset in
                            ImageRow(asset) {
                                vm.deleteSensitiveAsset(asset)
                            }
                        }
                        
                        ForEach(vm.sensitiveVideos, id: \.self) {
#if os(macOS)
                            Text($0.description)
#else
                            VideoRow($0)
#endif
                        }
                    }
                    .padding(8)
                    .animation(.default, value: vm.totalAssets)
                }
                .scrollIndicators(.never)
            }
        }
        .onFirstAppear {
            Task {
                await vm.checkPermission()
            }
        }
        .sheet($vm.sheetEnablePolicy) {
            SheetEnablePolicy()
        }
        .toolbar {
#if os(macOS)
            SFButton("folder") {
                vm.analyzeFolder(store.analyzeConcurrently)
            }
#endif
            Menu {
                Button("Reset", systemImage: "xmark") {
                    vm.sensitiveAssets = []
                    vm.sensitiveVideos = []
                    vm.assetCount = 0
                    vm.progress = 0
                    vm.processedAssets = 0
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .safeAreaInset(edge: .bottom) {
            PhotoLibraryActionInsetView()
        }
        .environment(vm)
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(ValueStore())
}
