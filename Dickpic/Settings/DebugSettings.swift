import SwiftUI

struct DebugSettings: View {
    @State private var sheetEnablePolicy = false
    @State private var fullScreenCover = false
    
    var body: some View {
        List {
            Button(String("Show intro")) {
                fullScreenCover = true
            }
            .foregroundStyle(.foreground)
            
            Button(String("Show permission warning"), systemImage: "exclamationmark.triangle") {
                sheetEnablePolicy = true
            }
            .foregroundStyle(.foreground)
        }
        .navigationTitle("Debug Settings")
        .toolbarTitleDisplayMode(.inline)
        .sheet($sheetEnablePolicy) {
            SheetEnablePolicy()
        }
        .sheet($fullScreenCover) {
            IntroScreen()
        }
    }
}
