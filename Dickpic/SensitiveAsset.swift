import CoreGraphics

struct SensitiveAsset: Identifiable, Hashable {
    let id: String
    let localIdentifier: String?
    let image: CGImage
    
    init(
        id: String,
        localIdentifier: String? = nil,
        image: CGImage
    ) {
        self.id = id
        self.localIdentifier = localIdentifier
        self.image = image
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
