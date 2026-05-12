import SwiftUI

struct VideoRow: View {
    @State private var vm = VideoRowVM()
    
    private let videoURL: URL
    private let unblurTrigger: Bool
    
    init(_ url: URL, unblurTrigger: Bool) {
        self.videoURL = url
        self.unblurTrigger = unblurTrigger
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
                    VideoThumbnail(videoURL)
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
        .onChange(of: unblurTrigger) { _, _ in
            isHidden = false
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "film")
                .padding(5)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 10))
                .padding(5)
        }
        .sheet($vm.showPreview) {
            QuickLookFile(vm.url)
        }
    }
}
