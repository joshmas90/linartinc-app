import SwiftUI

@main
struct LINARTApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var studio = StudioStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppIntroductionView()
                .environmentObject(store)
                .environmentObject(studio)
                .task { await studio.load(); await store.loadInquiryDraft() }
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { Task { await studio.flush(); await store.flushInquiryDraft() } }
                }
                .tint(Brand.bronze)
                .preferredColorScheme(.light)
        }
    }
}
