nonisolated enum FaceShape: String, Sendable {
    case tamago, marugao, omonaga, gyaku, base

    var label: String {
        switch self {
        case .tamago:  "卵型"
        case .marugao: "丸顔"
        case .omonaga: "面長"
        case .gyaku:   "逆三角"
        case .base:    "ベース型"
        }
    }

    var note: String {
        switch self {
        case .tamago:
            "上品で落ち着いた印象。バランス◎。ナチュラルな所作が映える。"
        case .marugao:
            "親しみやすく、若く見える。サイドシャドウで縦長に演出可能。"
        case .omonaga:
            "大人っぽくシャープな印象。横にハイライトでバランス調整。"
        case .gyaku:
            "都会的で、クール。あごのハイライトで丸みを足すと◎。"
        case .base:
            "健康的で、意志強め。エラ部分のシャドウで柔らかく。"
        }
    }
}
