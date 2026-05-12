import ScrechKit

struct ImageRowThumbnailView: View {
    private let image: UniversalImage
    private let isSquare: Bool
    
    init(_ image: UniversalImage, isSquare: Bool) {
        self.image = image
        self.isSquare = isSquare
    }
    
    var body: some View {
        Group {
            if isSquare {
#if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
#else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
#endif
            } else {
#if os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
#else
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
#endif
            }
        }
    }
}
