import SwiftUI
import QuickLooking

struct QuickLookFile: View {
    private let url: URL?
    
    init(_ url: URL?) {
        self.url = url
    }
    
    @State private var isHidden = true
    
    var body: some View {
        if let url {
            VStack {
                QuickLookView(url)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.default, value: url)
            .blur(radius: isHidden ? 10 : 0)
            //                .navigationTitle(name)
            .ignoresSafeArea(edges: .bottom)
            .toolbar {
                if isHidden {
                    Button {
                        withAnimation {
                            isHidden = false
                        }
                    } label: {
                        Image(systemName: "eye.slash")
                    }
                }
            }
        }
    }
}

//#Preview {
//    QuickLookFile()
//}
