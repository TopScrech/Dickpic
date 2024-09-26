import SwiftUI

struct HomeView: View {
    @State private var vm = PhotoLibraryVM()
    
    var body: some View {
        if vm.deniedAccess {
            Text("Access to the photo library has been denied. Please enable access in settings.")
                .padding()
                .navigationTitle("Photo Library")
        } else {
//            LazyVStack {
//                ScrollView {
//                    ForEach(vm.assets, id: \.self) { asset in
//                        ImageRow(asset)
//                    }
//                }
//            }
            List(vm.assets, id: \.self) { asset in
                ImageRow(asset)
            }
            .navigationTitle("Photo Library")
        }
    }
}

#Preview {
    HomeView()
}
