import ScrechKit
import QuickLooking

struct ImageRow: View {
    @State private var vm = ImageRowVM()
    
    private let asset: SensitiveAsset
    private let onDelete: () -> Void
    
    init(
        _ asset: SensitiveAsset,
        onDelete: @escaping () -> Void
    ) {
        self.asset = asset
        self.onDelete = onDelete
    }
    
    private let maxDimension = 64.0
    
    private var universalImage: UniversalImage {
#if os(iOS)
        UniversalImage(cgImage: asset.image)
#elseif os(macOS)
        // Original size
        let originalWidth = CGFloat(asset.image.width)
        let originalHeight = CGFloat(asset.image.height)
        
        // Scale factor
        let widthScale = maxDimension / originalWidth
        let heightScale = maxDimension / originalHeight
        let scale = min(1, min(widthScale, heightScale)) // Don't upscale
        
        // New size
        let newSize = NSSize(
            width: originalWidth * scale,
            height: originalHeight * scale
        )
        
        return UniversalImage(
            cgImage: asset.image,
            size: newSize
        )
#endif
    }
    
    @State private var isHidden = true
    
    var body: some View {
        Rectangle()
            .aspectRatio(1, contentMode: .fit)
            .foregroundColor(.clear)
            .overlay {
                Group {
#if os(macOS)
                    Image(nsImage: universalImage)
                        .resizable()
#else
                    Image(uiImage: universalImage)
                        .resizable()
#endif
                }
                // .frame(maxWidth: 256, maxHeight: 256)
                .scaledToFit()
                .clipped()
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .cornerRadius(8)
            .blur(radius: isHidden ? 8 : 0)
            .animation(.default, value: isHidden)
            .onTapGesture {
                isHidden.toggle()
            }
#if os(macOS)
            .onLongPressGesture {
                preview()
            }
#endif
            .contextMenu {
                Button("Preview", systemImage: "eye") {
                    preview()
                }

                if asset.localIdentifier != nil {
                    Button("Delete from Library", systemImage: "trash") {
                        onDelete()
                    }
                }
            }
#if os(macOS)
            .quickLookPreview($vm.showPreview, url: vm.url, blur: false)
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
