struct MakeupIntensity: Sendable {
    var base: Double = 25
    var highlight: Double = 20
    var shadow: Double = 18
    var eye: Double = 18
    var eyebrow: Double = 30

    init(
        base: Double = 25,
        highlight: Double = 20,
        shadow: Double = 18,
        eye: Double = 18,
        eyebrow: Double = 30
    ) {
        self.base = base
        self.highlight = highlight
        self.shadow = shadow
        self.eye = eye
        self.eyebrow = eyebrow
    }

    subscript(layer: MakeupLayer) -> Double {
        get {
            switch layer {
            case .base:      base
            case .highlight: highlight
            case .shadow:    shadow
            case .eye:       eye
            case .eyebrow:   eyebrow
            }
        }
        set {
            switch layer {
            case .base:      base      = newValue
            case .highlight: highlight = newValue
            case .shadow:    shadow    = newValue
            case .eye:       eye       = newValue
            case .eyebrow:   eyebrow   = newValue
            }
        }
    }
}
