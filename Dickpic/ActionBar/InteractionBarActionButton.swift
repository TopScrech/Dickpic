import SwiftUI

struct InteractionBarActionButton: View {
    @Environment(PhotoLibraryVM.self) private var vm
    @EnvironmentObject private var store: ValueStore
    
    private var actionTitle: LocalizedStringKey {
        vm.isProcessing ? "Cancel" : "Analyze"
    }
    
    private var buttonTint: Color {
        vm.isProcessing ? .red : .accentColor
    }
    
    var body: some View {
        Button(actionTitle, action: performAction)
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .tint(buttonTint)
            .disabled(vm.isProcessing && vm.progress > 0.95)
    }
    
    private func performAction() {
        if vm.isProcessing {
            vm.cancelProcessing()
        } else {
            if #available(iOS 26.0, *) {
                vm.registerBackgroundTask(
                    analyzeConcurrently: store.analyzeConcurrently,
                    analyzeNewestFirst: store.analyzeNewestFirst
                )
            } else {
                Task {
                    await vm.startAnalyze(
                        analyzeConcurrently: store.analyzeConcurrently,
                        analyzeNewestFirst: store.analyzeNewestFirst
                    )
                }
            }
        }
    }
}
