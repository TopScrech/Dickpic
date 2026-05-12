import SwiftUI

struct DebugSettings: View {
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        List {
            Button("Show intro") {
                fullScreenCover = true
            }
            .foregroundStyle(.foreground)
        }
    }
}
