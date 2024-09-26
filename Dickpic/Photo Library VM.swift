import ScrechKit
import Photos
import SensitiveContentAnalysis
import Combine

@Observable
final class PhotoLibraryVM: ObservableObject {
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
        
        allPhotos.enumerateObjects { asset, _, _ in
            self.fetchImage(asset)
        }
    }
    
    private func fetchImage(_ asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        
        options.deliveryMode = .highQualityFormat
        //        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            guard let result else {
                return
            }
            
            self.analyse(result)
        }
    }
    
    private func analyse(_ image: UIImage?) {
        Task {
            guard let cgImage = image?.cgImage else {
                incrementProgress()
                return
            }
            
            let isSensitive = await checkImage(cgImage)
            
            if isSensitive {
                sensitiveAssets.append(cgImage)
            }
            
            incrementProgress()
        }
    }
    
    private func incrementProgress() {
        main {
            self.processedPhotos += 1
            self.progress = Double(self.processedPhotos / self.totalPhotos)
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
