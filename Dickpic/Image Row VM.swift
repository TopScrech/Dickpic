import SwiftUI

@Observable
final class ImageRowVM {
    var showPreview = false
    var url: URL?
    
    func saveImageToTemporaryDirectory(_ image: UIImage) throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        
        // 2. Generate a unique file name using UUID to avoid name collisions
        let fileName = UUID().uuidString + ".png" // You can change the extension to ".jpg" if needed
        
        // 3. Create the full file URL
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        // 4. Convert UIImage to PNG data. Use jpegData(compressionQuality:) for JPEG format.
        guard let imageData = image.pngData() else {
            throw NSError(domain: "ImageConversionError",
                          code: 1001,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to convert UIImage to PNG data."])
        }
        
        // 5. Write the data to the file URL
        do {
            try imageData.write(to: fileURL, options: .atomic)
            
        } catch {
            throw NSError(domain: "FileWriteError",
                          code: 1002,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to write image data to temporary directory. \(error.localizedDescription)"])
        }
        
        url = fileURL
        
        if let url {
            showPreview = true
        }
    }
}
