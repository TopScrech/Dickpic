import SwiftUI

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    
    var body: some View {
        List {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings.")
                    .padding()
                    .navigationTitle("Photo Library")
            } else {
                Text("Total Photos: \(vm.totalPhotos) (\(vm.processedPhotos) processed)")
                    .animation(.default, value: vm.totalPhotos)
                    .animation(.default, value: vm.processedPhotos)
                    .contentTransition(.numericText())
                
                let progress = String(format: "%.0f%%", vm.progress * 100)
                
                ProgressView(value: vm.progress) {
                    Text("Progress: \(progress)")
                        .padding(.bottom, 8)
                }
                .animation(.default, value: vm.progress)
                .padding(.vertical, 5)
                
                ForEach(vm.sensitiveAssets, id: \.self) { asset in
                    ImageRow(asset)
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
}
