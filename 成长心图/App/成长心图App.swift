import SwiftUI

@main
struct 成长心图App: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("colorScheme") private var storedColorScheme: String = "system"

    var resolvedColorScheme: ColorScheme? {
        switch storedColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(resolvedColorScheme)
        }
    }
}
