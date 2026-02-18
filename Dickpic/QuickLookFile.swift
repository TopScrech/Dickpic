#if os(iOS)
import ScrechKit
import QuickLooking

struct QuickLookFile: View {
    private let url: URL?
    
    init(_ url: URL?) {
        self.url = url
    }
    
    @State private var isHidden = true
    
    var body: some View {
        VStack {
            if let url {
                QuickLookView(url)
                    .transition(.opacity)
                    .animation(.default, value: url)
            }
        }
        //        .navigationTitle(name)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .blur(radius: isHidden ? 10 : 0)
        .ignoresSafeArea(edges: .bottom)
        .toolbar {
            if let url {
                ShareLink(item: url)
            }
            
            if isHidden {
                SFButton("eye.slash") {
                    withAnimation {
                        isHidden = false
                    }
                }
            }
        }
    }
}

//#Preview {
//    QuickLookFile()
//}
#endif
