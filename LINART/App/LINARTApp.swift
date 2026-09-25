import SwiftUI

@main
struct LINARTApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            AppIntroductionView()
                .environmentObject(store)
                .tint(Brand.bronze)
                .preferredColorScheme(.light)
        }
    }
}
