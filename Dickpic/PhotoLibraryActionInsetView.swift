import SwiftUI

struct PhotoLibraryActionInsetView: View {
    @Environment(PhotoLibraryVM.self) private var vm
    @EnvironmentObject private var store: ValueStore
    @State private var elapsedProcessingTime = 0
    
    private var actionTitle: String {
        vm.isProcessing ? "Cancel" : "Analyze"
    }
    
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
                
                actionButton
                
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
    
    @ViewBuilder
    private var actionButton: some View {
        if vm.isProcessing {
            Button(actionTitle, action: performAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(buttonTint)
                .disabled(vm.progress > 0.95)
        } else {
            Button(actionTitle, action: performAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(buttonTint)
        }
    }
    
    private func performAction() {
        if vm.isProcessing {
            vm.cancelProcessing()
        } else {
            Task {
                await vm.startAnalyze(
                    analyzeConcurrently: store.analyzeConcurrently,
                    analyzeNewestFirst: store.analyzeNewestFirst
                )
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
        
        PhotoLibraryActionInsetView()
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
