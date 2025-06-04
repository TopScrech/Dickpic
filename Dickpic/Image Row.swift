import ScrechKit
import QuickLooking

struct ImageRow: View {
    @State private var vm = ImageRowVM()
    
    private let image: CGImage
    
    init(_ image: CGImage) {
        self.image = image
    }
    
    private var universalImage: UniversalImage {
#if os(iOS)
        UniversalImage(cgImage: image)
#elseif os(macOS)
        UniversalImage(
            cgImage: image,
            size: NSSize(
                width: 256,
                height: 256
            )
        )
#endif
    }
    
    @State private var isHidden = true
    
    var body: some View {
        Menu {
            Button("Preview") {
                preview()
            }
        } label: {
            Rectangle()
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.clear)
                .overlay {
                    Group {
#if os(macOS)
                        Image(nsImage: universalImage)
                            .resizable()
#else
                        Image(uiImage: uiImage)
                            .resizable()
#endif
                    }
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
#if os(macOS)
        .quickLookPreview($vm.showPreview, url: vm.url, blur: false)
        //        .quickLookPreview($showPreview, url: vm.url, blur: isHidden)
#else
        .sheet($vm.showPreview) {
            QuickLookFile(vm.url)
        }
#endif
    }
    
    private func preview() {
        do {
            try vm.saveImageToTemporaryDirectory(universalImage)
        } catch {
            print("Saving failed:", error.localizedDescription)
        }
    }
}
