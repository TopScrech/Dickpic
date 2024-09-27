import SwiftUI
import QuickLooking

struct ImageRow: View {
    @State private var vm = ImageRowVM()
    
    private let image: CGImage
    
    init(_ image: CGImage) {
        self.image = image
    }
    
    private var uiImage: UIImage {
        UIImage(cgImage: image)
    }
    
    @State private var isHidden = true
    
    var body: some View {
        Menu {
            Button("Preview") {
                do {
                    try vm.saveImageToTemporaryDirectory(uiImage)
                } catch {
                    print("Saving failed: \(error.localizedDescription)")
                }
            }
        } label: {
            Rectangle()
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.clear)
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
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
            QuickLookFile(vm.url)
        }
    }
}

