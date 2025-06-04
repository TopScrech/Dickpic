import ScrechKit
import Photos

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let analyzer = SensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var sensitiveVideos: [URL] = []
    var deniedAccess = false
    var sheetEnablePolicy = false
    var processedAssets = 0
    var assetCount = 0
    var progress = 0.0
    var processingTime: Int?
    
    var processAssetsTask: Task<Void, Never>?
    
    var totalAssets: Int {
        sensitiveAssets.count + sensitiveVideos.count
    }
    
    var processedPercent: Int {
        let percent = progress * 100
        return Int((percent / 5.0).rounded() * 5)
    }
    
    var isProcessing = false
    
    func checkPermission() async {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized:
            print("Authorized")
            
        case .limited:
            print("Limited")
            
        case .denied, .restricted:
            deniedAccess = true
            
        case .notDetermined:
            print("Not determined")
            
            await requestPermission()
            
        default:
            break
        }
    }
    
    private func requestPermission() async {
        PHPhotoLibrary.requestAuthorization { status in
            guard
                status == .authorized || status == .limited
            else {
                main {
                    self.deniedAccess = true
                }
                
                return
            }
        }
    }
    
    func cancelProcessing() {
        processAssetsTask?.cancel()
        isProcessing = true
    }
    
    func fetchAssets(analyzeConcurrently: Bool) async {
        let startTime = Date()
        isProcessing = true
        processingTime = nil
        
        // Cancel previous task
        processAssetsTask?.cancel()
        
        guard analyzer.checkPolicy() else {
            sheetEnablePolicy = true
            return
        }
        
        progress = 0
        assetCount = 0
        processedAssets = 0
        sensitiveAssets.removeAll()
        sensitiveVideos.removeAll()
        
        let fetchOptions = PHFetchOptions()
        var allAssets: PHFetchResult<PHAsset>
        
        fetchOptions.sortDescriptors = [
            //NSSortDescriptor(key: "creationDate", ascending: true) // Begin with old
            NSSortDescriptor(key: "creationDate", ascending: false) // Begin with new
        ]
        
        if ValueStore().analyzeVideos {
            allAssets = PHAsset.fetchAssets(with: fetchOptions)
        } else {
            allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        
        var assets: [PHAsset] = []
        
        assetCount = allAssets.count
        guard assetCount > 0 else {
            return
        }
        
        allAssets.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        let maxConcurrentTasks = analyzeConcurrently
        ? ProcessInfo.processInfo.activeProcessorCount
        : 1
        
        processAssetsTask = Task {
            await processAssets(assets, maxConcurrentTasks: maxConcurrentTasks)
            
            let elapsed = Date().timeIntervalSince(startTime)
            processingTime = Int(elapsed)
            
            isProcessing = false
        }
    }
    
    private func processAssets(
        _ assets: [PHAsset],
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
    
    private func analyzeAsset(_ asset: PHAsset) async {
        guard !Task.isCancelled else {
            return
        }
        
        switch asset.mediaType {
        case .image:
            do {
                let image = try await fetchAsset(asset)
                await analyseAsset(image)
            } catch {
                print("Error fetching image:", error.localizedDescription)
            }
            
        case .video:
            await analyzeVideo(asset)
            
        default:
            await incrementProcessedPhotos(false)
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
                sensitiveVideos.append(url)
            }
            
            await incrementProcessedPhotos()
        } catch {
            await incrementProcessedPhotos(false)
            print("Error fetching video:", error.localizedDescription)
        }
    }
    
    private func fetchVideoURL(_ asset: PHAsset) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            
            options.isNetworkAccessAllowed = false
            options.version = .current
            
            manager.requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, info in
                
                if let info, let error = info[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: urlAsset.url)
                } else {
                    let error = NSError(domain: "Invalid AVAsset", code: -1, userInfo: nil)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func checkVideo(_ url: URL) async -> Bool {
        do {
            let isSensitive = try await analyzer.checkVideo(url)
            return isSensitive
        } catch {
            print("Failed to check video:", error.localizedDescription)
            return false
        }
    }
    
    private func incrementProcessedPhotos(_ isSuccess: Bool = true) async {
        if isSuccess {
            processedAssets += 1
        }
        
        progress = Double(processedAssets) / Double(assetCount)
    }
}

extension PhotoLibraryVM {
    private func analyseAsset(_ image: UniversalImage?) async {
#if os(macOS)
        let cgImage = image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
#else
        let cgImage = image?.cgImage
#endif
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
            sensitiveAssets.append(cgImage)
        }
        
        await incrementProcessedPhotos()
    }
    
    private func fetchAsset(_ asset: PHAsset) async throws -> UniversalImage? {
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
}
