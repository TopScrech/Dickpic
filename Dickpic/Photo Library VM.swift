import ScrechKit
import Photos
import SensitiveContentAnalysis

@Observable
final class PhotoLibraryVM: ObservableObject {
    private let analyzer = SCSensitivityAnalyzer()
    
    var sensitiveAssets: [CGImage] = []
    var deniedAccess = false
    
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
            DispatchQueue.main.async {
                self.deniedAccess = true
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                main {
                    if newStatus == .authorized || newStatus == .limited {
                        self?.fetchPhotos()
                    } else {
                        self?.deniedAccess = true
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
        
        allPhotos.enumerateObjects { [weak self] asset, _, _ in
            self?.fetchImage(asset)
        }
    }
    
    private func fetchImage(_ asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        
        options.deliveryMode = .opportunistic
        options.isSynchronous = false
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                self.analyse(result)
            }
        }
    }
    
    private func analyse(_ image: UIImage?) {
        Task {
            if let cgImage = image?.cgImage {
                await checkImage(cgImage) { isSensitive in
                    if isSensitive {
                        self.sensitiveAssets.append(cgImage)
                    }
                }
            }
        }
    }
    
    func checkImage(_ url: URL, completion: @escaping (Bool) -> Void) async {
        do {
            let handler = try await analyzer.analyzeImage(at: url)
            completion(handler.isSensitive)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func checkImage(_ image: CGImage, completion: @escaping (Bool) -> Void) async {
        do {
            let handler = try await analyzer.analyzeImage(image)
            completion(handler.isSensitive)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func checkVideo(_ url: URL, completion: @escaping (Bool) -> Void) async {
        do {
            let handler = analyzer.videoAnalysis(forFileAt: url)
            completion(try await handler.hasSensitiveContent().isSensitive)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func checkPolicy() -> Bool {
        let policy = analyzer.analysisPolicy
        
        if policy == .disabled {
            print("Analysis is disabled")
            return false
        } else {
            return true
        }
    }
}
