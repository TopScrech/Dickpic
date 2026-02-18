import SwiftUI

struct ProgressButton: View {
    private let name: LocalizedStringKey
    private let color: Color
    private let progress: Double
    private let action: () -> Void
    
    init(
        _ name: LocalizedStringKey,
        color: Color = .blue,
        progress: Double = 0,
        action: @escaping () -> Void = {}
    ) {
        self.name = name
        self.color = color
        self.progress = min(max(progress, 0), 1)
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            ZStack(alignment: .leading) {
                // Фон кнопки с пониженной прозрачностью
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.gradient.opacity(progress == 0 ? 1 : 0.3))
                
                // Активная часть фона, соответствующая прогрессу
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.gradient)
                        .frame(width: CGFloat(progress) * geometry.size.width)
                        .animation(.linear(duration: 0.2), value: progress)
                }
                .clipped()
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .opacity((progress > 0 && progress < 1) ? 0.5 : 1)
            .overlay {
                Text(name)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var progress1 = 0.0
    @Previewable @State var progress2 = 0.3
    @Previewable @State var isLoading = false
    
    VStack(spacing: 20) {
        ProgressButton("Start", progress: progress1) {
            withAnimation {
                progress1 += 0.1
            }
        }
        
        ProgressButton("Progress...", progress: progress2) {
            withAnimation {
                progress2 += 0.1
            }
        }
        
        ProgressButton("Complete", progress: 1) {
            print("Это не будет выполнено, так как кнопка заблокирована")
        }
    }
}
