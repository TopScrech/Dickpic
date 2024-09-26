import SwiftUI

struct LibraryAnalysisView: View {
    @State private var vm = PhotoLibraryVM()
    
    var body: some View {
        List {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings.")
                    .padding()
                    .navigationTitle("Photo Library")
            } else {
                Text("Total Photos: \(vm.totalPhotos) (\(vm.processedPhotos) processed)")
                
                ProgressView("Progress", value: vm.progress)
                
                Text(String(format: "Progress: %.0f%%", vm.progress * 100))
                
                Section {
                    Button("Analyse") {
                        vm.fetchPhotos()
                    }
                }
                
                ForEach(vm.sensitiveAssets, id: \.self) { asset in
                    ImageRow(asset)
                }
            }
        }
        .navigationTitle("Photo Library")
    }
}

#Preview {
    LibraryAnalysisView()
}
