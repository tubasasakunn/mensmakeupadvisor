import UIKit

final class MockAnalysisService: AnalysisServiceProtocol, Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult {
        try await Task.sleep(for: .seconds(1.5))
        return AnalysisResult.mock
    }
}
