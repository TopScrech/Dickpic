import SwiftUI

final class ValueStore: ObservableObject {
    @AppStorage("download_originals") var downloadOriginals = false
    @AppStorage("analyze_concurrently") var analyzeConcurrently = true
    @AppStorage("analyze_videos") var analyzeVideos = true
    @AppStorage("analyze_newest_first") var analyzeNewestFirst = true
    @AppStorage("blur_sensitive_media") var blurSensitiveMedia = true
    @AppStorage("square_photo_grid") var squarePhotoGrid = true
    
    @AppStorage("show_intro") var showIntro = true
}
