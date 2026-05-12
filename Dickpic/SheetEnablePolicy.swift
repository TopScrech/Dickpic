import ScrechKit

struct SheetEnablePolicy: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            ContentUnavailableView {
                Label {
                    Text("Sensitive Content Warnings are disabled")
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red.gradient)
                }
            } description: {
                Text("To enable this feature, follow these steps:")
            }
            .frame(maxHeight: 160)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Open Settings")
                Text("2. Navigate to **Privacy & Security**, scroll down and select **Sensetive Content Warning**")
                Text("3. Turn on the toggle and return to the app")
            }
            .frame(maxWidth: 420, alignment: .leading)
            .padding(.horizontal)
            
            BigButton("Dismiss", color: .green.opacity(0.5)) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SheetEnablePolicy()
}
