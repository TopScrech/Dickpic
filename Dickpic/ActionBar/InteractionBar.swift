import SwiftUI

struct InteractionBar: View {
    @Environment(PhotoLibraryVM.self) private var vm
    
    @State private var elapsedProcessingTime = 0
    
    private var buttonTint: Color {
        vm.isProcessing ? .red : .accentColor
    }
    
    var body: some View {
        VStack(spacing: 8) {
            if vm.isProcessing {
                ProgressView(value: vm.progress)
                    .tint(buttonTint)
            }
            
            HStack {
                if hasAnalyzeStarted {
                    ViewThatFits {
                        HStack(spacing: 0) {
                            PhotoLibraryMetricView("Processed", value: processedValue)
                            
                            if let displayedProcessingTime {
                                Text(" • ")
                                    .secondary()
                                
                                processingTimeView(displayedProcessingTime)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            PhotoLibraryMetricView("Processed", value: processedValue)
                            
                            if let displayedProcessingTime {
                                HStack(spacing: 0) {
                                    Text(" • ")
                                        .secondary()
                                    
                                    processingTimeView(displayedProcessingTime)
                                }
                            }
                        }
                    }
                    .animation(.default, value: vm.assetCount)
                    .animation(.default, value: vm.processedAssets)
                    .animation(.default, value: vm.processingTime)
                    .numericTransition()
                }
                
                if hasAnalyzeStarted {
                    Spacer(minLength: 12)
                } else {
                    Spacer()
                }
                
                InteractionBarActionButton()
                
                if !hasAnalyzeStarted {
                    Spacer()
                }
            }
        }
        .footnote()
        .monospacedDigit()
        .padding()
        .background(.bar)
        .task(id: vm.isProcessing) {
            guard vm.isProcessing else {
                return
            }
            
            elapsedProcessingTime = 0
            
            while vm.isProcessing && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                elapsedProcessingTime += 1
            }
        }
    }
    
    private var processedValue: String {
        "\(vm.processedAssets.formatted())/\(vm.assetCount.formatted()) · \(vm.processedPercent)%"
    }
    
    private var displayedProcessingTime: Int? {
        if vm.isProcessing {
            elapsedProcessingTime
        } else {
            vm.processingTime
        }
    }
    
    private func processingTimeView(_ processingTime: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .secondary()
            
            Text("\(processingTime.formatted())s")
        }
    }
    
    private var hasAnalyzeStarted: Bool {
        vm.isProcessing || vm.assetCount > 0 || vm.processingTime != nil
    }
}

#Preview {
    @Previewable @State var vm = PhotoLibraryVM()
    
    VStack {
        Spacer()
        InteractionBar()
    }
    .environment(vm)
    .environmentObject(ValueStore())
    .onAppear {
        vm.assetCount = 1240
        vm.processedAssets = 380
        vm.progress = 0.3
        vm.isProcessing = true
    }
}
