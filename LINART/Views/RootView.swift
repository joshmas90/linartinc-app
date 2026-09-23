import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }.tag(0)
            NavigationStack { ProjectsView() }
                .tabItem { Label("Projects", systemImage: "square.grid.2x2") }.tag(1)
            NavigationStack { PlannerView() }
                .tabItem { Label("My Project", systemImage: "square.and.pencil") }.tag(2)
            NavigationStack { AboutView() }
                .tabItem { Label("About", systemImage: "building.2") }.tag(3)
        }
        .sheet(isPresented: $store.inquiryPresented) {
            NavigationStack { InquiryView() }
                .environmentObject(store)
        }
    }
}

struct CatalogUnavailableView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 20) {
            ContentUnavailableView("Portfolio unavailable", systemImage: "photo", description: Text("The bundled portfolio could not be loaded. You can still contact LINART."))
            Button("Try again") { store.reloadCatalog() }.buttonStyle(.bordered)
            ContactActions()
        }.padding(24)
    }
}
