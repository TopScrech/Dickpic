import SwiftUI
import Photos

struct ImageRow: View {
    @State private var analyzer = SensitivityAnalyzer()
    
    private let asset: PHAsset
    
    init(_ asset: PHAsset) {
        self.asset = asset
    }
    
    @State private var image: UIImage? = nil
    @State private var isSensitive: Bool?
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 100, height: 100)
                    .scaledToFit()
                    .clipped()
            } else {
                Color.gray
            }
        }
        .onAppear(perform: fetchImage)
        .overlay(alignment: .bottomTrailing) {
            if let isSensitive {
                Image(systemName: isSensitive ? "eye.slash" : "eye")
            } else {
                Button {
                    analyse(image)
                } label: {
                    Image(systemName: "questionmark.circle.dashed")
                }
            }
        }
    }
    
    private func fetchImage() {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                self.image = result
            }
        }
    }
    
    private func analyse(_ image: UIImage?) {
        Task {
            if let cgImage = image?.cgImage {
                await analyzer.checkImage(cgImage) { result in
                    isSensitive = result
                }
            }
        }
    }
}
