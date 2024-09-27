import ScrechKit
import Photos
import SensitiveContentAnalysis
import Combine

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
    private let analyzer = SCSensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var deniedAccess = false
    var totalPhotos = 0
    var progress = 0.0
    var processedPhotos = 0
    
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
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
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
            
            // Start initial tasks up to the concurrency limit
            for _ in 0..<maxConcurrentTasks {
                if let asset = iterator.next() {
                    group.addTask(priority: .userInitiated) { [weak self] in
                        await self?.fetchAndAnalyze(asset)
                    }
                }
            }
            
            // As each task completes, add a new one
            while let asset = iterator.next() {
                // Wait for any task to complete
                await group.next()
                
                // Add the next asset to the group
                group.addTask(priority: .userInitiated) { [weak self] in
                    await self?.fetchAndAnalyze(asset)
                }
            }
            
            // The group will automatically wait for all remaining tasks to complete
        }
    }
    
    //    private func processAssetsSequentially(_ assets: [PHAsset]) {
    //        Task {
    //            for asset in assets {
    //                await fetchAndAnalyze(asset)
    //                // Update progress after each asset
    //                await updateProgress()
    //            }
    //        }
    //    }
    
    private func fetchAndAnalyze(_ asset: PHAsset) async {
        do {
            let image = try await fetchImage(for: asset)
            await analyse(image)
        } catch {
            print("Error fetching image: \(error.localizedDescription)")
        }
    }
    
    private func fetchImage(for asset: PHAsset) async throws -> UIImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            options.resizeMode = .none
            options.isNetworkAccessAllowed = false // If true, and the requested image is not stored on the local device, Photos downloads the image from iCloud
            
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
    
    private func analyse(_ image: UIImage?) async {
        guard let cgImage = image?.cgImage else {
            return
        }
        
        let isSensitive = await checkImage(cgImage)
        
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
}
