import SwiftUI
import QuickLooking

struct ImageRow: View {
    private let image: CGImage
    
    init(_ image: CGImage) {
        self.image = image
    }
    
    private var uiImage: UIImage {
        UIImage(cgImage: image)
    }
    
    @State private var isHidden = true
    @State private var showPreview = false
    @State private var url: URL?
    
    var body: some View {
        Menu {
            Button("Preview") {
                do {
                    url = try saveImageToTemporaryDirectory(uiImage)
                } catch {
                    print("Saving fauled: \(error.localizedDescription)")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showPreview = true
                }
            }
        } label: {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: 100, height: 100)
                .scaledToFit()
                .clipped()
                .blur(radius: isHidden ? 5 : 0)
                .animation(.default, value: isHidden)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "eye.slash")
                }
        } primaryAction: {
            isHidden.toggle()
        }
        .sheet($showPreview) {
            if let url {
                QuickLookView(url)
            }
        }
    }
}
