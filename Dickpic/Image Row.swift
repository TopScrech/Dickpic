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
    
    var body: some View {
        Image(uiImage: uiImage)
            .resizable()
            .frame(width: 100, height: 100)
            .scaledToFit()
            .clipped()
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "eye.slash")
            }
    }
}
