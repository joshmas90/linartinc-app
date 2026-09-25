import SwiftUI

@main
struct LINARTApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var studio = StudioStore()
    @StateObject private var cloud = CloudStudioStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppIntroductionView()
                .environmentObject(store)
                .environmentObject(studio)
                .environmentObject(cloud)
                .task { await studio.load(); await store.loadInquiryDraft(); await cloud.load() }
                .onOpenURL { url in
                    guard url.scheme?.lowercased() == "com.linartinc.linart" else { return }
                    store.selectedTab = .studio
                    cloud.handle(url)
                }
                .alert("Email verification", isPresented: Binding(get: { cloud.authenticationMessage != nil }, set: { if !$0 { cloud.authenticationMessage = nil } })) {
                    Button("Continue to My Project") { store.selectedTab = .studio; cloud.authenticationMessage = nil }
                } message: { Text(cloud.authenticationMessage ?? "") }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { Task { await studio.flush(); await store.flushInquiryDraft() } }
                }
                .tint(Brand.bronze)
                .preferredColorScheme(.light)
        }
    }
}
