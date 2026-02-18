import ScrechKit
import Photos
import BackgroundTasks
import OSLog

@Observable
final class PhotoLibraryVM: ObservableObject {
    let analyzer = SensitivityAnalyzer()
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "dev.topscrech.Dickpic",
        category: "PhotoLibraryVM"
    )
    
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
            logger.info("Authorized")
            
        case .limited:
            logger.info("Limited")
            
        case .denied, .restricted:
            deniedAccess = true
            
        case .notDetermined:
            logger.info("Not determined")
            
            await requestPermission()
            
        default:
            break
        }
    }
    
    private func requestPermission() async {
        let status = await requestAuthorizationStatus()

        guard
            status == .authorized || status == .limited
        else {
            deniedAccess = true
            return
        }
    }
    
    func cancelProcessing() {
        processAssetsTask?.cancel()
        isProcessing = true
    }

    func startAnalyze(
        analyzeConcurrently: Bool
    ) async {
        let startTime = Date()
        isProcessing = true
        processingTime = nil

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
            await self.processAssets(
                assets,
                maxConcurrentTasks: self.maxConcurrentTasks(analyzeConcurrently),
                task: nil
            )

            let elapsed = Date().timeIntervalSince(startTime)
            self.processingTime = Int(elapsed)
            self.isProcessing = false
        }
    }

    @MainActor
    func deleteSensitiveAsset(_ asset: SensitiveAsset) {
        guard let localIdentifier = asset.localIdentifier else {
            return
        }

        deleteAssetFromLibrary(localIdentifier: localIdentifier) { [weak self] didSucceed, error in
            if let error {
                self?.logger.error("Failed to delete sensitive asset: \(error.localizedDescription, privacy: .public)")
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
            NSSortDescriptor(key: "creationDate", ascending: true) // Start from oldest
            //            NSSortDescriptor(key: "creationDate", ascending: false) // Start from newest
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
    
    func processAssets(
        _ assets: [PHAsset],
        maxConcurrentTasks: Int,
        task: BGContinuedProcessingTask?
    ) async {
        logger.debug("maxConcurrentTasks: \(maxConcurrentTasks)")
        _ = maxConcurrentTasks

        for asset in assets {
            guard !Task.isCancelled else {
                break
            }

            await analyzeAsset(asset, task: task)
        }
    }
    
    private func analyzeAsset(
        _ asset: PHAsset,
        task: BGContinuedProcessingTask?
    ) async {
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
                logger.error("Error fetching image: \(error.localizedDescription, privacy: .public)")
            }
            
        case .video:
            await analyzeVideo(asset)
            
        default:
            await incrementProcessedPhotos(false)
        }
        
        task?.progress.completedUnitCount += 1
    }
    
    // MARK: Image
    func checkImage(_ image: CGImage) async -> Bool {
        do {
            return try await analyzer.checkImage(image)
        } catch {
            logger.error("\(error.localizedDescription, privacy: .public)")
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
            logger.error("Error fetching video: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    nonisolated private func requestAuthorizationStatus() async -> PHAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    nonisolated private func fetchVideoUrl(
        _ asset: PHAsset
    ) async throws -> URL {
        
        try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            var didResume = false
            
            options.isNetworkAccessAllowed = false
            options.version = .current
            
            manager.requestAVAsset(
                forVideo: asset,
                options: options
            ) { avAsset, _, info in
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
            logger.error("Failed to check video: \(error.localizedDescription, privacy: .public)")
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
    
    nonisolated private func fetchAsset(
        _ asset: PHAsset,
        downloadOriginals: Bool
    ) async throws -> UniversalImage? {
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
