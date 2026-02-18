import SwiftUI

struct IntroScreen: View {
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("🔞")
                .blur(radius: 6)
                .fontSize(100)
                .padding(.bottom, 16)
            
            Text("Oops, this could be sensitive! Let's avoid unpleasant situations")
                .largeTitle(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 80)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("⏳")
                        .fontSize(32)
                    
                    Text("No need to waste your time sifting through thousands of media library assets")
                }
                
                HStack {
                    Text("😌")
                        .fontSize(32)
                    
                    Text("A single scan that ensures your peace of mind")
                }
                
                HStack {
                    Text("👙")
                        .fontSize(32)
                    
                    Text("Your true beauty is a personal attribute that belongs solely to you")
                }
            }
            .secondary()
            .padding(.horizontal)
            
            Spacer()
            
            BigLink("Why would I trust this app?", color: .red) {
                IntroScreen2($fullScreenCover)
            }
            
            BigButton("Gotcha!") {
                fullScreenCover = false
            }
        }
        .rounded()
    }
}

//#Preview {
//    IntroScreen()
//}
