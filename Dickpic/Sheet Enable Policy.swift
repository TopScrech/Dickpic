import ScrechKit

struct SheetEnablePolicy: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red.gradient)
                
                Text("Sensitive Content Warnings are disabled")
            }
            .title(.bold)
            
            VStack(alignment: .leading) {
                Text("To enable this feature, follow these steps:")
                    .title3(.semibold)
                    .padding(.vertical)
                
#if os(macOS)
                Text("1. Open Settings")
#else
                Button {
                    openSettings()
                } label: {
                    Text("1. ") +
                    
                    Text("Open Settings")
                        .underline()
                }
                .foregroundStyle(.foreground)
#endif
                
                Text("2. Navigate to **Privacy & Security**, scroll down and select **Sensetive Content Warning**")
                
                Text("3. Turn on the switch and return to the app")
                
                Spacer()
                
                BigButton("Dismiss", color: .green) {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    SheetEnablePolicy()
}
