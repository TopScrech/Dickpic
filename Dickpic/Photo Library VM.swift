import ScrechKit
import Photos

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let analyzer = SensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var sensitiveVideos: [URL] = []
    var deniedAccess = false
    var sheetEnablePolicy = false
    var processedPhotos = 0
    var totalPhotos = 0
    var progress = 0.0
    
    init() {
        checkPermission()
    }
    
    private func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("Authorized")
            
        case .limited:
            print("Limited")
            
        case .denied, .restricted:
            main {
                self.deniedAccess = true
            }
            
        case .notDetermined:
            print("Not determined")
            
            requestPermission()
            
        default:
            break
        }
    }
    
    private func requestPermission() {
        PHPhotoLibrary.requestAuthorization { newStatus in
            main {
                guard newStatus == .authorized || newStatus == .limited else {
                    self.deniedAccess = true
                    return
                }
            }
        }
    }
    
    func fetchAssets() {
        guard analyzer.checkPolicy() else {
            sheetEnablePolicy = true
            return
        }
        
        progress = 0
        totalPhotos = 0
        processedPhotos = 0
        sensitiveAssets.removeAll()
        sensitiveVideos.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        var allPhotos: PHFetchResult<PHAsset>
        
        if ValueStore().analyzeVideos {
            allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        } else {
            allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        
        var assets: [PHAsset] = []
        
        totalPhotos = allPhotos.count
        
        guard totalPhotos > 0 else {
            return
        }
        
        allPhotos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        Task {
            await processAssets(assets)
        }
    }
    
    private func processAssets(_ assets: [PHAsset]) async {
        await withTaskGroup(of: Void.self) { group in
            var iterator = assets.makeIterator()
            
            let maxConcurrentTasks: Int
            
            if ValueStore().analyzeConcurrently {
                maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
            } else {
                maxConcurrentTasks = 1
            }
            
            for _ in 0..<maxConcurrentTasks {
                if let asset = iterator.next() {
                    group.addTask(priority: .userInitiated) { [weak self] in
                        await self?.fetchAndAnalyze(asset)
                    }
                }
            }
            
            while let asset = iterator.next() {
                await group.next()
                
                group.addTask(priority: .userInitiated) { [weak self] in
                    await self?.fetchAndAnalyze(asset)
                }
            }
        }
    }
    
    private func fetchAndAnalyze(_ asset: PHAsset) async {
        switch asset.mediaType {
        case .image:
            do {
                let image = try await fetchImage(for: asset)
                await analyse(image)
            } catch {
                print("Error fetching image: \(error.localizedDescription)")
            }
            
        case .video:
            await analyzeVideo(asset)
            
        default:
            await incrementProcessedPhotos()
        }
    }
    
    // MARK: Image
    
    func checkImage(_ image: CGImage) async -> Bool {
        do {
            return try await analyzer.checkImage(image)
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    // MARK: Video
    private func analyzeVideo(_ asset: PHAsset) async {
        do {
            let url = try await fetchVideoURL(asset)
            
#if targetEnvironment(simulator)
            let isSensitive = true
#else
            let isSensitive = await checkVideo(url)
#endif
            
            if isSensitive {
                await MainActor.run {
                    self.sensitiveVideos.append(url)
                }
            }
        } catch {
            print("Error fetching video: \(error.localizedDescription)")
        }
        
        await incrementProcessedPhotos()
    }
    
    private func fetchVideoURL(_ asset: PHAsset) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            
            options.isNetworkAccessAllowed = false
            options.version = .current
            
            manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                if let info, let error = info[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url)
                } else {
                    continuation.resume(throwing: NSError(domain: "Invalid AVAsset", code: -1, userInfo: nil))
                }
            }
        }
    }
    
    func checkVideo(_ url: URL) async -> Bool {
        do {
            let isSensitive = try await analyzer.checkVideo(url)
            return isSensitive
        } catch {
            print("Failed to check video: \(error.localizedDescription)")
            return false
        }
    }
    
    private func incrementProcessedPhotos() async {
        await MainActor.run {
            self.processedPhotos += 1
            self.progress = Double(self.processedPhotos) / Double(self.totalPhotos)
        }
    }
}

#warning("Extract")
extension PhotoLibraryVM {
#if os(macOS)
    private func analyse(_ image: NSImage?) async {
        guard let cgImage = image?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            await incrementProcessedPhotos()
            return
        }
        
#if targetEnvironment(simulator)
        let isSensitive = true
#else
        let isSensitive = await checkImage(cgImage)
#endif
        
        if isSensitive {
            await MainActor.run {
                self.sensitiveAssets.append(cgImage)
            }
        }
        
        await incrementProcessedPhotos()
    }
#else
    private func analyse(_ image: UIImage?) async {
        guard let cgImage = image?.cgImage else {
            await incrementProcessedPhotos()
            return
        }
        
#if targetEnvironment(simulator)
        let isSensitive = true
#else
        let isSensitive = await checkImage(cgImage)
#endif
        
        if isSensitive {
            await MainActor.run {
                self.sensitiveAssets.append(cgImage)
            }
        }
        
        await incrementProcessedPhotos()
    }
#endif
    
#if os(macOS)
    private func fetchImage(for asset: PHAsset) async throws -> NSImage? {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = ValueStore().downloadOriginals
            
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { result, info in
                if let info, let error = info[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: result)
            }
        }
    }
#else
    private func fetchImage(for asset: PHAsset) async throws -> UIImage? {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = ValueStore().downloadOriginals
            
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { result, info in
                if let info, let error = info[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: result)
            }
        }
    }
#endif
}
