import Observation
import SwiftUI

@Observable
@MainActor
final class AppRouter {
    var path: NavigationPath = NavigationPath()

    enum Destination: Hashable {
        case settings
    }

    func push(_ destination: Destination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
