import SwiftUI
import AVFoundation

struct VideoThumbnail: View {
    private let url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        Group {
            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
            } else {
                Color.gray
                    .onAppear {
                        generateThumbnail()
                    }
            }
        }
    }
    
    private func generateThumbnail() {
        let asset = AVURLAsset(url: url)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        generator.generateCGImageAsynchronously(for: time) { cgImage, _, error in
            guard let cgImage, error == nil else {
                return
            }
            
            Task { @MainActor in
                thumbnail = UIImage(cgImage: cgImage)
            }
        }
    }
}

//#Preview {
//    VideoThumbnail()
//}
