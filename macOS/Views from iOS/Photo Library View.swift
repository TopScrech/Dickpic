import SwiftUI

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var storage: SettingsStorage
    
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
                        
                        ForEach(vm.sensitiveVideos, id: \.self) { videoURL in
                            // VideoRow(videoURL)
                        }
                    }
                    .animation(.default, value: vm.sensitiveAssets)
                    .animation(.default, value: vm.sensitiveVideos)
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
                Text("Total Photos: `\(vm.totalPhotos)` (`\(vm.processedPhotos)` processed)")
                    .animation(.default, value: vm.totalPhotos)
                    .animation(.default, value: vm.processedPhotos)
                    .numericTransition()
#endif
                ProgressButton("Analyze", progress: vm.progress) {
                    vm.fetchAssets()
                }
            }
            .padding(8)
            .padding(.vertical, 8)
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(SettingsStorage())
}
