import SwiftUI

struct IntroScreen2: View {
    @Binding private var fullScreenCover: Bool
    
    init(_ fullScreenCover: Binding<Bool>) {
        _fullScreenCover = fullScreenCover
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("🤓")
                .fontSize(100)
                .padding(.bottom, 16)
            
            Text("Why would I trust this app?")
                .largeTitle(.bold)
                .multilineTextAlignment(.center)
                .padding(.bottom, 80)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("🙈")
                        .fontSize(32)
                    
                    Text("Assets from the **hidden** folder are not scanned unless you explicitly opt-in")
                }
                .secondary()
                .padding(.horizontal)
                
                HStack {
                    Text("🌧️")
                        .fontSize(32)
                    
                    Text("Dickpic utilizes **offline on-device** processing, ensuring that no data is transmitted to the cloud")
                }
                .secondary()
                .padding(.horizontal)
                
                HStack {
                    Text("🍏")
                        .fontSize(32)
                    
                    Text("The app employs an official Apple-developed [framework](https://developer.apple.com/documentation/sensitivecontentanalysis) to identify sensitive images")
                }
                .secondary()
                .padding(.horizontal)
                
                //                HStack {
                //                    Text("👨🏿‍💻")
                //                        .fontSize(32)
                //
                //                    Text("Open-source distribution allows independent parties to audit [the code](https://github.com/topscrech/SwiftUI-Intro) and contribute to the project")
                //                }
                //                .secondary()
                //                .padding(.horizontal)
            }
            
            Spacer()
            
            BigButton("Alright", color: .green) {
                fullScreenCover = false
            }
        }
        .rounded()
        .navigationBarBackButtonHidden()
    }
}

//#Preview {
//    IntroScreen2()
//}
