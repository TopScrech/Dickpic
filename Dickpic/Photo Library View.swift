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
                            VideoRow(videoURL)
                        }
                    }
                }
            }
        }
        .navigationTitle("Photo Library")
        .safeAreaInset(edge: .bottom) {
            ProgressButton("Analyze", progress: vm.progress) {
                vm.fetchPhotos()
            }
            .padding(.bottom, 5)
        }
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(SettingsStorage())
}
