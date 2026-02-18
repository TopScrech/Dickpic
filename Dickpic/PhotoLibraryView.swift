import ScrechKit

struct PhotoLibraryView: View {
    @State private var vm = PhotoLibraryVM()
    @EnvironmentObject private var store: ValueStore
    
    private static let initialColumns = 3
    
#if os(macOS)
    private let gridItemSize = 160.0
#else
    private let gridItemSize = 120.0
#endif
    
    private var gridColumns: [GridItem] {[
        GridItem(.adaptive(minimum: gridItemSize, maximum: gridItemSize))
    ]}
    
    var body: some View {
        VStack {
            if vm.deniedAccess {
                Text("Access to the photo library has been denied. Please enable access in settings")
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(vm.sensitiveAssets) { asset in
                            ImageRow(asset) {
                                vm.deleteSensitiveAsset(asset)
                            }
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
        .toolbar {
#if os(macOS)
            SFButton("folder") {
                vm.analyzeFolder(store.analyzeConcurrently)
            }
#endif
            Menu {
                Button {
                    vm.sensitiveAssets = []
                    vm.sensitiveVideos = []
                    vm.assetCount = 0
                    vm.progress = 0
                    vm.processedAssets = 0
                } label: {
                    Label("Reset", systemImage: "xmark")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Text("Total Assets: \(vm.assetCount)")
                    .animation(.default, value: vm.assetCount)
                    .numericTransition()
                
                HStack(spacing: 0) {
                    Text("Processed: \(vm.processedAssets)")
                    
                    Text(" / \(vm.processedPercent)%")
                }
                .animation(.default, value: vm.processedAssets)
                .numericTransition()
                
                if let processingTime = vm.processingTime {
                    Text("Processing time: \(processingTime)s")
                }
                
                ProgressButton(
                    vm.isProcessing ? "Cancel" : "Analyze",
                    color: vm.isProcessing ? .red : .blue,
                    progress: vm.progress
                ) {
                    if vm.isProcessing {
                        vm.cancelProcessing()
                    } else {
                        Task {
                            await vm.startAnalyze(
                                analyzeConcurrently: store.analyzeConcurrently
                            )
                        }
                    }
                }
                .disabled(vm.isProcessing && vm.progress > 0.95)
                //                .contextMenu {
                //                    Button {
                //                        Task {
                //                            await vm.startAnalyze(
                //                                analyzeConcurrently: true
                //                            )
                //                        }
                //                    } label: {
                //                        Label("Analyze Concurrently", systemImage: "square.grid.3x3")
                //                    }
                //
                //                    Button {
                //                        Task {
                //                            await vm.startAnalyze(
                //                                analyzeConcurrently: false
                //                            )
                //                        }
                //                    } label: {
                //                        Label("Analyze Sequentually", systemImage: "square")
                //                    }
                //                }
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
