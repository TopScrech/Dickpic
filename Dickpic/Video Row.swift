import SwiftUI
import AVFoundation

struct VideoRow: View {
    @State private var vm = VideoRowVM()
    
    private let videoURL: URL
    
    init(_ url: URL) {
        self.videoURL = url
    }
    
    @State private var isHidden = true
    
    var body: some View {
        Menu {
            Button("Preview") {
                vm.previewVideo(videoURL)
            }
        } label: {
            Rectangle()
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.clear)
                .overlay {
                    VideoThumbnail(url: videoURL)
                        .scaledToFill()
                        .clipped()
                        .cornerRadius(8)
                }
                .cornerRadius(8)
                .blur(radius: isHidden ? 5 : 0)
                .animation(.default, value: isHidden)
        } primaryAction: {
            isHidden.toggle()
        }
        .sheet($vm.showPreview) {
            NavigationView {
                QuickLookFile(vm.url)
            }
        }
    }
}

struct VideoThumbnail: View {
    let url: URL
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
        let asset = AVAsset(url: url)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
            thumbnail = UIImage(cgImage: cgImage)
        }
    }
}

@Observable
final class VideoRowVM {
    var showPreview = false
    var url: URL?
    
    func previewVideo(_ videoURL: URL) {
        url = videoURL
        showPreview = true
    }
}
