import SwiftUI

final class ValueStore: ObservableObject {
    @AppStorage("download_originals") var downloadOriginals = false
    @AppStorage("analyze_concurrently") var analyzeConcurrently = true
    @AppStorage("analyze_videos") var analyzeVideos = true
    
    @AppStorage("selected_tab") var selectedTab = 0
    @AppStorage("show_intro") var showIntro = true
}
