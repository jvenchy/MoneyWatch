import SwiftUI

@main
struct MoneyWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 350, minHeight: 500)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
