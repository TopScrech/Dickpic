import SwiftUI

struct BigLink<Destination: View>: View {
    private let name: LocalizedStringKey
    private let color: Color
    private let destination: () -> Destination
    
    init(_ name: LocalizedStringKey, color: Color = .blue, destination: @escaping () -> Destination) {
        self.name = name
        self.color = color
        self.destination = destination
    }
    
    var body: some View {
        NavigationLink {
            destination()
        } label: {
            Text(name)
                .semibold()
                .foregroundStyle(.white)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .background(color.gradient, in: .rect(cornerRadius: 16))
                .padding(.horizontal)
        }
    }
}

#Preview {
    BigLink("Preview") {
        Text("Preview")
    }
}
