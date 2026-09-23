import SwiftUI

@main
struct LINARTApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Brand.bronze)
                .preferredColorScheme(.light)
        }
    }
}
