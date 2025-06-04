import SwiftUI

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    private static let initialColumns = 3
    
#if os(macOS)
    private var gridColumns: [GridItem] {[
        GridItem(.adaptive(minimum: 160, maximum: 160))
    ]}
#else
    private var gridColumns: [GridItem] {[
        GridItem(.adaptive(minimum: 120, maximum: 120))
    ]}
#endif
    
    var body: some View {
        VStack {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(vm.sensitiveAssets, id: \.self) { asset in
                            ImageRow(asset)
                        }
                        
                        ForEach(vm.sensitiveVideos, id: \.self) { videoUrl in
#if os(macOS)
                            Text(videoUrl.description)
#else
                            VideoRow(videoUrl)
#endif
                        }
                    }
                    .padding(8)
                    .animation(.default, value: vm.totalAssets)
                }
            }
        }
        .navigationTitle("Photo Library")
        .onFirstAppear {
            Task {
                await vm.checkPermission()
            }
        }
        .sheet($vm.sheetEnablePolicy) {
            SheetEnablePolicy()
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Text("Total Assets: `\(vm.totalPhotos)` (`\(vm.processedAssets)` processed)")
                    .animation(.default, value: vm.totalPhotos)
                    .animation(.default, value: vm.processedAssets)
                    .numericTransition()
                
                ProgressButton("Analyze", progress: vm.progress) {
                    Task {
                        await vm.fetchAssets()
                    }
                }
            }
#if os(macOS)
            .padding(8)
            .padding(.vertical, 8)
            .buttonStyle(.plain)
#else
            .padding(.bottom, 5)
#endif
        }
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(ValueStore())
}
