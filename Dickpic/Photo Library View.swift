import SwiftUI

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    private static let initialColumns = 3
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
    
    var body: some View {
        VStack {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings.")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(vm.sensitiveAssets, id: \.self) { asset in
                            ImageRow(asset)
                        }
                        
                        ForEach(vm.sensitiveVideos, id: \.self) { videoUrl in
                            VideoRow(videoUrl)
                        }
                    }
                    .animation(.default, value: vm.totalAssets)
                }
            }
        }
        .navigationTitle("Photo Library")
        .sheet($vm.sheetEnablePolicy) {
            SheetEnablePolicy()
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
#if DEBUG
                Text("Total Assets: `\(vm.totalPhotos)` (`\(vm.processedAssets)` processed)")
                    .animation(.default, value: vm.totalPhotos)
                    .animation(.default, value: vm.processedAssets)
#endif
                ProgressButton("Analyze", progress: vm.progress) {
                    Task {
                        await vm.fetchAssets()
                    }
                }
            }
            .padding(.bottom, 5)
        }
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(ValueStore())
}
