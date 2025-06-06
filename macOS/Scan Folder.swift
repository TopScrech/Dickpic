import SwiftUI

extension PhotoLibraryVM {
    func analyzeFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Select a folder containing images"
        
        guard
            panel.runModal() == .OK,
            let folderURL = panel.url
        else {
            print("No folder selected")
            exit(1)
        }
        
        let imageExtensions: Set<String> = [
            "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"
        ]
        
        let fm = FileManager.default
        var imageFiles: [URL] = []
        
        if let enumerator = fm.enumerator(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) {
            for case let fileUrl as URL in enumerator {
                let ext = fileUrl.pathExtension.lowercased()
                
                if imageExtensions.contains(ext) {
                    imageFiles.append(fileUrl)
                }
            }
        }
        
        guard !imageFiles.isEmpty else {
            print("No image files found in the selected folder or its subfolders")
            return
        }
        
        print("Image files found:", imageFiles.count)
        
        let analyzer = SensitivityAnalyzer()
        
        Task {
            for url in imageFiles {
                if try await analyzer.checkImage(url) {
                    imageUrlToCgImage(url)
                }
            }
            
        }
    }
    
    func imageUrlToCgImage(_ url: URL) {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard
            let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            print("Error loading image:", url)
            return
        }
        
        sensitiveAssets.append(cgImage)
    }
}
