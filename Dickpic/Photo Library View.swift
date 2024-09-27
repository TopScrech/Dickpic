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
                    .padding()
                    .navigationTitle("Photo Library")
            } else {
                Text("Total Photos: \(vm.totalPhotos) (\(vm.processedPhotos) processed)")
                    .animation(.default, value: vm.totalPhotos)
                    .animation(.default, value: vm.processedPhotos)
                
                let progress = String(format: "%.0f%%", vm.progress * 100)
                
                ProgressView(value: vm.progress) {
                    Text("Progress: \(progress)")
                        .padding(.bottom, 8)
                }
                .animation(.default, value: vm.progress)
                .padding(.vertical, 5)
                
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(vm.sensitiveAssets, id: \.self) { asset in
                            ImageRow(asset)
                        }
                    }
                }
            }
        }
        .navigationTitle("Photo Library")
        .safeAreaInset(edge: .bottom) {
            if vm.totalPhotos == 0 {
                BigButton("Analyse") {
                    vm.fetchPhotos()
                }
                .padding(.bottom, 5)
            }
        }
    }
}

#Preview {
    PhotoLibraryView()
        .environmentObject(SettingsStorage())
}
