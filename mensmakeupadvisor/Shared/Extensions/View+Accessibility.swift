import SwiftUI

extension View {
    func aid(_ id: String) -> some View {
        accessibilityIdentifier(id)
    }
}
