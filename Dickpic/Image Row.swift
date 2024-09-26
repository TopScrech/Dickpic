import SwiftUI
import Photos

struct ImageRow: View {
    @State private var analyzer = SensitivityAnalyzer()
    
    private let image: CGImage
    
    init(_ image: CGImage) {
        self.image = image
    }
    
    private var uiImage: UIImage {
        UIImage(cgImage: image)
    }
    
    @State private var isHidden = true
    
    var body: some View {
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
            .onTapGesture {
                isHidden.toggle()
            }
    }
}
