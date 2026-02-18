import SwiftUI

extension PhotoLibraryVM {
    func analyzeFolder(_ analyzeConcurrently: Bool) {
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
        
        var imageFiles: [URL] = []
        
        if let enumerator = FileManager.default.enumerator(
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
        
        isProcessing = true
        
        guard !imageFiles.isEmpty else {
            print("No image files found in the selected folder or its subfolders")
            return
        }
        
        print("Image files found:", imageFiles.count)
        assetCount = imageFiles.count
        
        processAssetsTask = Task {
            await processAssets(imageFiles, maxConcurrentTasks: maxConcurrentTasks(analyzeConcurrently))
            
            //            let elapsed = Date().timeIntervalSince(startTime)
            //            processingTime = Int(elapsed)
            
            isProcessing = false
        }
    }
    
    private func processAssets(
        _ assets: [URL],
        maxConcurrentTasks: Int
    ) async {
        print("maxConcurrentTasks:", maxConcurrentTasks)
        
        await withTaskGroup(of: Void.self) { group in
            var iterator = assets.makeIterator()
            
            for _ in 0..<maxConcurrentTasks {
                if let asset = iterator.next() {
                    group.addTask(priority: .userInitiated) { [weak self] in
                        guard !Task.isCancelled else {
                            return
                        }
                        
                        await self?.analyzeAsset(asset)
                    }
                }
            }
            
            while let asset = iterator.next() {
                guard !Task.isCancelled else {
                    break
                }
                
                await group.next()
                
                group.addTask(priority: .userInitiated) { [weak self] in
                    guard !Task.isCancelled else {
                        return
                    }
                    
                    await self?.analyzeAsset(asset)
                }
            }
        }
    }
    
    func analyzeAsset(_ url: URL) async {
        guard !Task.isCancelled else {
            return
        }
        
        let cgImage = imageUrlToCgImage(url)
        
        guard let cgImage else {
            await incrementProcessedPhotos(false)
            return
        }
        
#if targetEnvironment(simulator)
        let isSensitive = true
#else
        let isSensitive = await checkImage(cgImage)
#endif
        if isSensitive {
            sensitiveAssets.append(
                SensitiveAsset(
                    id: url.absoluteString,
                    image: cgImage
                )
            )
        }
        
        await incrementProcessedPhotos()
    }
    
    func imageUrlToCgImage(_ url: URL) -> CGImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        
        guard
            let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions),
            let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        else {
            print("Error loading image:", url)
            return nil
        }
        
        return cgImage
    }
}
