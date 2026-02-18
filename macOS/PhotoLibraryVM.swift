import ScrechKit
import Photos

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let analyzer = SensitivityAnalyzer()
    
    var sensitiveAssets: [SensitiveAsset] = []
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
    
    func maxConcurrentTasks(_ analyzeConcurrently: Bool) -> Int {
        analyzeConcurrently ? ProcessInfo.processInfo.activeProcessorCount : 1
    }
    
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
        let status = await requestAuthorizationStatus()

        guard status == .authorized || status == .limited else {
            deniedAccess = true
            return
        }
    }
    
    func cancelProcessing() {
        processAssetsTask?.cancel()
        isProcessing = true
    }
    
    func startAnalyze(analyzeConcurrently: Bool) async {
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
        
        let assets = await fetchAssets()
        
        processAssetsTask = Task {
            await processAssets(assets, maxConcurrentTasks: maxConcurrentTasks(analyzeConcurrently))
            
            let elapsed = Date().timeIntervalSince(startTime)
            processingTime = Int(elapsed)
            
            isProcessing = false
        }
    }

    @MainActor
    func deleteSensitiveAsset(_ asset: SensitiveAsset) {
        guard let localIdentifier = asset.localIdentifier else {
            return
        }

        deleteAssetFromLibrary(localIdentifier: localIdentifier) { [weak self] didSucceed, error in
            if let error {
                print("Failed to delete sensitive asset:", error.localizedDescription)
            }

            guard didSucceed else {
                return
            }

            self?.sensitiveAssets.removeAll { $0.id == asset.id }
        }
    }

    nonisolated private func deleteAssetFromLibrary(
        localIdentifier: String,
        completion: @escaping @MainActor (Bool, Error?) -> Void
    ) {
        PHPhotoLibrary.shared().performChanges {
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [localIdentifier],
                options: nil
            )
            guard fetchResult.count > 0 else {
                return
            }

            PHAssetChangeRequest.deleteAssets(fetchResult)
        } completionHandler: { didSucceed, error in
            Task { @MainActor in
                completion(didSucceed, error)
            }
        }
    }
    
    func fetchAssets() async -> [PHAsset] {
        let fetchOptions = PHFetchOptions()
        var allAssets: PHFetchResult<PHAsset>
        
        fetchOptions.sortDescriptors = [
            //NSSortDescriptor(key: "creationDate", ascending: true) // Start from oldest
            NSSortDescriptor(key: "creationDate", ascending: false) // Start from newest
        ]
        
        if ValueStore().analyzeVideos {
            allAssets = PHAsset.fetchAssets(with: fetchOptions)
        } else {
            allAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        }
        
        var assets: [PHAsset] = []
        
        assetCount = allAssets.count
        
        guard assetCount > 0 else {
            return []
        }
        
        allAssets.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        return assets
    }
    
    private func processAssets(_ assets: [PHAsset], maxConcurrentTasks: Int) async {
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
                let image = try await fetchAsset(
                    asset,
                    downloadOriginals: ValueStore().downloadOriginals
                )
                await analyseAsset(
                    image,
                    identifier: asset.localIdentifier
                )
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
            let url = try await fetchVideoUrl(asset)
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
    
    nonisolated private func requestAuthorizationStatus() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated private func fetchVideoUrl(_ asset: PHAsset) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            var didResume = false
            
            options.isNetworkAccessAllowed = false
            options.version = .current
            
            manager.requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                guard !didResume else {
                    return
                }
                
                if let info, let error = info[PHImageErrorKey] as? Error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                
                if let urlAsset = avAsset as? AVURLAsset {
                    didResume = true
                    continuation.resume(returning: urlAsset.url)
                } else {
                    let error = NSError(domain: "Invalid AVAsset", code: -1, userInfo: nil)
                    didResume = true
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
    
    func incrementProcessedPhotos(_ isSuccess: Bool = true) async {
        if isSuccess {
            processedAssets += 1
        }
        
        progress = Double(processedAssets) / Double(assetCount)
    }
}

extension PhotoLibraryVM {
    private func analyseAsset(
        _ image: UniversalImage?,
        identifier: String
    ) async {
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
            sensitiveAssets.append(
                SensitiveAsset(
                    id: identifier,
                    localIdentifier: identifier,
                    image: cgImage
                )
            )
        }
        
        await incrementProcessedPhotos()
    }
    
    nonisolated private func fetchAsset(_ asset: PHAsset, downloadOriginals: Bool) async throws -> UniversalImage? {
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            var didResume = false
            
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = downloadOriginals
            
            manager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { result, info in
                guard !didResume else {
                    return
                }

                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }

                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    didResume = true
                    continuation.resume(returning: nil)
                    return
                }
                
                if let info, let error = info[PHImageErrorKey] as? Error {
                    didResume = true
                    continuation.resume(throwing: error)
                    return
                }
                
                didResume = true
                continuation.resume(returning: result)
            }
        }
    }
}
