import SwiftUI
import SwiftData

@main
struct AuraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: AuraEntry.self)
    }
}
