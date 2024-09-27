import SwiftUI

final class SettingsStorage: ObservableObject {
    @AppStorage("download_originals") var downloadOriginals = false
    @AppStorage("analyze_concurrently") var analyzeConcurrently = true
}
