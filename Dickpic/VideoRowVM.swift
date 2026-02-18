import Foundation

@Observable
final class VideoRowVM {
    var showPreview = false
    var url: URL?
    
    func previewVideo(_ videoURL: URL) {
        url = videoURL
        showPreview = true
    }
}
