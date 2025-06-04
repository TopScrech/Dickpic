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
                Text("Total Assets: \(vm.totalPhotos)")
                    .animation(.default, value: vm.totalPhotos)
                    .numericTransition()
                
                HStack(spacing: 0) {
                    Text("Processed: \(vm.processedAssets)")
                    
                    Text("(\(vm.processedPercent)%)")
//                    Text("(\(String(format: "%.1f", vm.processedPercent))%)")
                }
                .animation(.default, value: vm.processedAssets)
                .numericTransition()
                
                ProgressButton(
                    vm.isProcessing ? "Cancel" : "Analyze",
                    color: vm.isProcessing ? .red : .blue,
                    progress: vm.progress
                ) {
                    if vm.isProcessing {
                        vm.cancelProcessing()
                    } else {
                        Task {
                            await vm.fetchAssets()
                        }
                    }
                }
                .disabled(vm.isProcessing && vm.progress > 0.95)
            }
            .monospacedDigit()
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
