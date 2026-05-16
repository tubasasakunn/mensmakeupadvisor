struct MakeupIntensity: Sendable {
    // 初期値は全 0 = 化粧無し。Studio に入った直後は素の写真を見せ、
    // プリセット適用 or FINE TUNE スライダー操作で明確に「化粧 ON」が
    // 分かるようにする。以前は初期値が入っていたため、画面に来た瞬間から
    // 中途半端な化粧が乗っており「変化していないように見える」原因だった。
    var base: Double = 0
    var highlight: Double = 0
    var shadow: Double = 0
    var eye: Double = 0
    var eyebrow: Double = 0

    init(
        base: Double = 0,
        highlight: Double = 0,
        shadow: Double = 0,
        eye: Double = 0,
        eyebrow: Double = 0
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
