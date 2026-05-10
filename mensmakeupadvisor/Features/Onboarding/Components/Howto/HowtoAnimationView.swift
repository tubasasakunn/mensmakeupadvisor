import SwiftUI

struct HowtoAnimationView: View {
    let step: String

    var body: some View {
        switch step.lowercased() {
        case "base":      HowtoBaseAnimation()
        case "brows":     HowtoBrowsAnimation()
        case "eyes":      HowtoEyesAnimation()
        case "highlight": HowtoHighlightAnimation()
        case "shadow":    HowtoShadowAnimation()
        default:          EmptyView()
        }
    }

    static func hasAnimation(for step: String) -> Bool {
        ["base", "brows", "eyes", "highlight", "shadow"].contains(step.lowercased())
    }
}
