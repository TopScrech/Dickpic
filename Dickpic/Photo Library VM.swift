import ScrechKit
import Photos
import SensitiveContentAnalysis
import Combine

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let maxConcurrentTasks = ProcessInfo.processInfo.activeProcessorCount
    private let semaphore: DispatchSemaphore
    private let analyzer = SCSensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var deniedAccess = false
    var totalPhotos = 0
    var progress = 0.0
    var processedPhotos = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.semaphore = DispatchSemaphore(value: maxConcurrentTasks)
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
                    if newStatus == .authorized || newStatus == .limited {
                        self.fetchPhotos()
                    } else {
                        self.deniedAccess = true
                    }
                }
            }
            
        default:
            break
        }
    }
    
    func fetchPhotos() {
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
        
        processAssetsInParallel(assets)
    }
    
    private func processAssetsInParallel(_ assets: [PHAsset]) {
        Task {
            for asset in assets {
                // Wait for the semaphore before starting a new task
                semaphore.wait()
                
                Task.detached {
                    await self.fetchAndAnalyze(asset)
                    // Signal the semaphore after the task is complete
                    self.semaphore.signal()
                }
            }
            
            // Wait until all tasks are finished
            // This ensures that the Task doesn't complete until all assets are processed
            for _ in 0..<self.maxConcurrentTasks {
                self.semaphore.wait()
            }
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
                if let info = info, let error = info[PHImageErrorKey] as? Error {
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
        
        await incrementProcessedPhotos()
        
        let isSensitive = await checkImage(cgImage)
        
        if isSensitive {
            await MainActor.run {
                self.sensitiveAssets.append(cgImage)
            }
        }
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
    
    
    //    func fetchPhotos() {
    //        progress = 0
    //        processedPhotos = 0
    //
    //        let fetchOptions = PHFetchOptions()
    //
    //        fetchOptions.sortDescriptors = [
    //            NSSortDescriptor(key: "creationDate", ascending: false)
    //        ]
    //
    //        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    //        totalPhotos = allPhotos.count
    //
    //        guard totalPhotos > 0 else {
    //            return
    //        }
    //
    //        allPhotos.enumerateObjects { asset, _, _ in
    //            self.fetchImage(asset)
    //        }
    //    }
    //
    //    private func fetchImage(_ asset: PHAsset) {
    //        let manager = PHImageManager.default()
    //        let options = PHImageRequestOptions()
    //        options.deliveryMode = .highQualityFormat
    //        options.isSynchronous = false
    //        options.resizeMode = .none
    //        options.isNetworkAccessAllowed = true
    //
    //        // Используйте PHImageManagerMaximumSize для получения изображения в оригинальном размере
    //        manager.requestImage(
    //            for: asset,
    //            targetSize: PHImageManagerMaximumSize,
    //            contentMode: .aspectFit,
    //            options: options
    //        ) { [weak self] result, info in
    //            if let info, let error = info[PHImageErrorKey] as? Error {
    //                print("Ошибка загрузки изображения: \(error.localizedDescription)")
    //                return
    //            }
    //
    //            guard let result else {
    //                print("Не удалось получить изображение.")
    //                return
    //            }
    //
    //            self?.analyse(result)
    //        }
    //    }
    //
    //    private func analyse(_ image: UIImage?) {
    //        Task {
    //            guard let cgImage = image?.cgImage else {
    //                incrementProgress()
    //                return
    //            }
    //
    //            let isSensitive = await checkImage(cgImage)
    //
    //            if isSensitive {
    //                main {
    //                    self.sensitiveAssets.append(cgImage)
    //                }
    //            }
    //
    //            incrementProgress()
    //        }
    //    }
    //
    //    private func incrementProgress() {
    //        main {
    //            self.processedPhotos += 1
    //            self.progress = Double(self.processedPhotos / self.totalPhotos)
    //        }
    //    }
    //
    //    func checkImage(_ image: CGImage) async -> Bool {
    //        do {
    //            let handler = try await analyzer.analyzeImage(image)
    //            return handler.isSensitive
    //        } catch {
    //            print(error.localizedDescription)
    //            return false
    //        }
    //    }
}
