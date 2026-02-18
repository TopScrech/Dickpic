import ScrechKit

@Observable
final class ImageRowVM {
    var showPreview = false
    var url: URL?
    
    func saveImageToTemporaryDirectory(_ image: UniversalImage) throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".png"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
#if os(iOS)
        guard
            let imageData = image.pngData()
        else {
            throw NSError(
                domain: "ImageConversionError",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert UIImage to PNG data"
                ]
            )
        }
#elseif os(macOS)
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let imageData = bitmap.representation(using: .png, properties: [:])
        else {
            throw NSError(
                domain: "ImageConversionError",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to convert NSImage to PNG data"
                ]
            )
        }
#endif
        
        do {
#if os(iOS)
            try imageData.write(to: fileURL, options: .atomic)
#elseif os(macOS)
            try imageData.write(to: fileURL)
#endif
        } catch {
            throw NSError(
                domain: "FileWriteError",
                code: 1002,
                userInfo: [
                    NSLocalizedDescriptionKey: "Failed to write image data to temporary directory: \(error.localizedDescription)"
                ]
            )
        }
        
        url = fileURL
        showPreview = true
    }
}
