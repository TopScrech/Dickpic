import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ValueStore
    
    @State private var fullScreenCover = false
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            PhotoLibraryView()
                .tag(0)
                .tabItem {
                    Label("Analysis", systemImage: "eye.slash")
                }
            
            SettingsView()
                .tag(1)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .navigationTitle(store.selectedTab == 0 ? "Photo Library" : "Settings")
        .toolbar {
            if store.selectedTab == 1 {
                NavigationLink {
                    DebugSettings($fullScreenCover)
                } label: {
                    Label("Debug", systemImage: "hammer")
                }
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
