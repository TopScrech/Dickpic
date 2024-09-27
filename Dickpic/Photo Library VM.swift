import ScrechKit
import Photos
import SensitiveContentAnalysis
import Combine

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
    private let analyzer = SCSensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var sensitiveVideos: [URL] = []
    var deniedAccess = false
    var processedPhotos = 0
    var totalPhotos = 0
    var progress = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
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
            
            PHPhotoLibrary.requestAuthorization { newStatus in
                main {
                    guard newStatus == .authorized || newStatus == .limited else {
                        self.deniedAccess = true
                        return
                    }
                    
                    self.fetchPhotos()
                }
            }
            
        default:
            break
        }
    }
    
    func fetchPhotos() {
        progress = 0
        processedPhotos = 0
        
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let allPhotos = PHAsset.fetchAssets(with: fetchOptions)
        totalPhotos = allPhotos.count
        
        guard totalPhotos > 0 else {
            return
        }
        
        var assets: [PHAsset] = []
        allPhotos.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        Task {
            await processAssetsInParallel(assets)
        }
    }
    
    private func processAssetsInParallel(_ assets: [PHAsset]) async {
        await withTaskGroup(of: Void.self) { group in
            var iterator = assets.makeIterator()
            
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
    
    private func fetchImage(for asset: PHAsset) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = false
            
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
    
    private func analyzeVideo(_ asset: PHAsset) async {
        do {
            let url = try await fetchVideoURL(for: asset)
            
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
    
    private func fetchVideoURL(for asset: PHAsset) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            options.version = .original
            
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
    
    private func incrementProcessedPhotos() async {
        await MainActor.run {
            self.processedPhotos += 1
            self.progress = Double(self.processedPhotos) / Double(self.totalPhotos)
        }
    }
    
    func checkImage(_ image: CGImage) async -> Bool {
        do {
            let handler = try await analyzer.analyzeImage(image)
            return handler.isSensitive
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    func checkVideo(_ url: URL) async -> Bool {
        do {
            let handler = try await analyzer.analyzeVideo( url)
            return handler.isSensitive
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

extension SCSensitivityAnalyzer {
    func analyzeVideo(_ url: URL) async throws -> VideoSensitivityHandler {
        // Example implementation: Analyze video frames for sensitivity
        let asset = AVAsset(url: url)
        
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else {
            return VideoSensitivityHandler(isSensitive: false)
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        let isSensitive = try await self.analyzeImage(uiImage.cgImage!)
        
        return VideoSensitivityHandler(isSensitive: isSensitive.isSensitive)
    }
}

struct VideoSensitivityHandler {
    let isSensitive: Bool
}
