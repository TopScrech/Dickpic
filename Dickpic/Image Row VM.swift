import SwiftUI

@Observable
final class ImageRowVM {
    var showPreview = false
    var url: URL?
    
    func saveImageToTemporaryDirectory(_ image: UIImage) throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        
        let fileName = UUID().uuidString + ".png"
        
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        guard let imageData = image.pngData() else {
            throw NSError(
                domain: "ImageConversionError",
                code: 1001,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert UIImage to PNG data."]
            )
        }
        
        do {
            try imageData.write(to: fileURL, options: .atomic)
            
        } catch {
            throw NSError(
                domain: "FileWriteError",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Failed to write image data to temporary directory. \(error.localizedDescription)"]
            )
        }
        
        url = fileURL
        
        if let url {
            showPreview = true
        }
    }
}
