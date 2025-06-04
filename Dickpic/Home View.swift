import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ValueStore
    
    @State private var fullScreenCover = false
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
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
        .sheet($fullScreenCover) {
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
            if store.showIntro {
                fullScreenCover = true
                store.showIntro = false
            }
        }
    }
}

#Preview {
    HomeView()
}
