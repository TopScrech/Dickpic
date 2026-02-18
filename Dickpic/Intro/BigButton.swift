import SwiftUI

struct BigButton: View {
    private let name: LocalizedStringKey
    private let color: Color
    private let action: () -> Void
    
    init(_ name: LocalizedStringKey, color: Color = .blue, action: @escaping () -> Void = {}) {
        self.name = name
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
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
    BigButton("Preview")
}
