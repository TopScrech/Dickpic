import SwiftUI
import Photos

@Observable
final class PhotoLibraryVM: ObservableObject {
    var assets: [PHAsset] = []
    var deniedAccess = false
    
    init() {
        checkPermission()
    }
    
    private func checkPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized, .limited:
            fetchPhotos()
            
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.deniedAccess = true
            }
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    DispatchQueue.main.async {
                        self?.fetchPhotos()
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.deniedAccess = true
                    }
                }
            }
            
        default:
            break
        }
    }
    
    private func fetchPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.enumerateObjects { [weak self] (asset, _, _) in
            self?.assets.append(asset)
        }
    }
}
