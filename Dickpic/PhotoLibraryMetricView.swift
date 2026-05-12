import SwiftUI

struct PhotoLibraryMetricView: View {
    private let title: LocalizedStringKey
    private let value: String
    
    init(_ title: LocalizedStringKey, value: String) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .secondary()
            
            Text(value)
        }
    }
}
