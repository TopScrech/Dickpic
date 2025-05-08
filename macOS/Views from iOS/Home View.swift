import SwiftUI

struct HomeView: View {
    @AppStorage("show_intro") private var showIntro = true
    
    @State private var fullScreenCover = false
    
    var body: some View {
        TabView {
            PhotoLibraryView()
                .tabItem {
                    Label("Analysis", systemImage: "eye.slash")
                }
            
            SettingsView($fullScreenCover)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
#if os(macOS)
        .popover(isPresented: $fullScreenCover) {
#warning("merge")
            NavigationView {
                IntroScreen($fullScreenCover)
            }
        }
#else
        .fullScreenCover($fullScreenCover) {
            NavigationView {
                IntroScreen($fullScreenCover)
            }
        }
#endif
        .task {
            if showIntro {
                fullScreenCover = true
                showIntro = false
            }
        }
    }
}

#Preview {
    HomeView()
}
