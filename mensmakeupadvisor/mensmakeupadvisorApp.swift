import SwiftUI
import SwiftData

@main
struct mensmakeupadvisorApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedLook.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do { return try ModelContainer(for: schema, configurations: [config]) }
        catch { fatalError("ModelContainer error: \(error)") }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.analysisService, resolvedAnalysisService)
        }
        .modelContainer(sharedModelContainer)
    }

    private var resolvedAnalysisService: any AnalysisServiceProtocol {
        AppEnvironment.isMockMode ? MockAnalysisService() : AnalysisService()
    }
}
