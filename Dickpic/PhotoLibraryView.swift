import ScrechKit

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    @State private var fullScreenCover = false
    
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
                    .animation(.default, value: vm.totalAssets)
                }
                .scrollIndicators(.never)
            }
        }
        .navigationTitle("Photo Library")
        .toolbarTitleDisplayMode(.inline)
        .sheet($vm.sheetEnablePolicy) {
            SheetEnablePolicy()
        }
#if os(macOS)
        .sheet($fullScreenCover) {
            IntroScreen()
        }
#else
        .fullScreenCover($fullScreenCover) {
            IntroScreen()
        }
#endif
        .task {
            if store.showIntro {
                fullScreenCover = true
                store.showIntro = false
            }
        }
        .onFirstAppear {
            Task {
                await vm.checkPermission()
            }
        }
        .photoLibraryToolbar()
        .overlay(alignment: .bottom) {
            InteractionBar()
        }
        .environment(vm)
    }
}

//#Preview {
//    PhotoLibraryView()
//        .environmentObject(ValueStore())
//}
