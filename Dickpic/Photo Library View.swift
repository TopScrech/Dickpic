import SwiftUI

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    private static let initialColumns = 3
    
    @State private var gridColumns = Array(
        repeating: GridItem(.flexible()),
        count: initialColumns
    )
    
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
                    .animation(.default, value: vm.totalAssets)
                }
            }
        }
        .navigationTitle("Photo Library")
        .onFirstAppear {
            vm.checkPermission()
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
