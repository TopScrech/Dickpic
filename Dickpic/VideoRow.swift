import SwiftUI

struct VideoRow: View {
    @EnvironmentObject private var store: ValueStore
    @State private var vm = VideoRowVM()
    @State private var isBlurred = true
    
    private let videoURL: URL
    
    init(_ url: URL) {
        self.videoURL = url
    }

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
                    if store.squarePhotoGrid {
                        VideoThumbnail(videoURL)
                            .scaledToFill()
                            .clipped()
                            .clipShape(.rect(cornerRadius: 8))
                    } else {
                        VideoThumbnail(videoURL)
                            .scaledToFit()
                            .clipped()
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                .clipShape(.rect(cornerRadius: 8))
                .blur(radius: isBlurred ? 5 : 0)
                .animation(.default, value: isBlurred)
                .animation(.default, value: store.squarePhotoGrid)
        } primaryAction: {
            toggleBlur()
        }
        .task {
            isBlurred = store.blurSensitiveMedia
        }
        .onChange(of: store.blurSensitiveMedia) { _, newValue in
            isBlurred = newValue
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
        .padding(4)
    }
    
    private func toggleBlur() {
        isBlurred.toggle()
    }
}
