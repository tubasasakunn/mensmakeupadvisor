import OSLog
import SwiftData
import SwiftUI

private let appLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "App")

@main
struct mensmakeupadvisorApp: App {
    @State private var appState = AppState()

    let sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedLook.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // SwiftData 不能 = アプリの全機能が壊れる前提。OSLog に残してから停止する。
            appLog.fault("ModelContainer init failed: \(String(describing: error), privacy: .public)")
            fatalError("ModelContainer error: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(\.analysisService, resolvedAnalysisService)
                .task {
                    if AppEnvironment.isScreenshotMode {
                        await appState.runScreenshotFlow()
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var resolvedAnalysisService: any AnalysisServiceProtocol {
        AppEnvironment.isMockMode ? MockAnalysisService() : AnalysisService()
    }
}
