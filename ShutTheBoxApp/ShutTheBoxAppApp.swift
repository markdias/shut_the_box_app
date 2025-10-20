import SwiftUI

@main
struct ShutTheBoxAppApp: App {
    @StateObject private var store = GameStore()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        }
    }
}
