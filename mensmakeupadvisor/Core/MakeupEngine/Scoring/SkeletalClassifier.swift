import Foundation

// 2.1 骨格による顔判定
// makeup_claude/loadmap/2/2.1-skeletal/main.py の `extract_features` / `score_types` /
// `classify` を移植。プロトタイプ・スケール・重みは Python 版と同一の値を使う。
enum SkeletalClassifier {
    enum SkeletalType: String, CaseIterable, Sendable {
        case oval
        case round
        case long
        case invertedTriangle = "inverted_triangle"
        case base

        var label: String {
            switch self {
            case .oval:              "卵型 (縦1.5:横1・なめらかな輪郭)"
            case .round:             "丸型 (縦≈横・頬ふっくら)"
            case .long:              "面長 (縦>>横)"
            case .invertedTriangle:  "逆三角形 (おでこ広・あご先シュッ)"
            case .base:              "ベース型 (エラ張り・あご平ら)"
            }
        }

        // FaceShape (アプリ既存 enum) とのマッピング
        var faceShape: FaceShape {
            switch self {
            case .oval: .tamago
            case .round: .marugao
            case .long: .omonaga
            case .invertedTriangle: .gyaku
            case .base: .base
            }
        }
    }

    struct Features: Sendable {
        var aspect: Double
        var cheekToTemple: Double
        var jawRatio: Double
        var foreheadRatio: Double
        var chinAngle: Double
        var taper: Double
    }

    struct Result: Sendable {
        var type: SkeletalType
        var typeLabel: String
        var features: Features
        var scores: [SkeletalType: Double]
        var metrics: FaceMetrics
    }

    // Python: PROTOTYPES
    private nonisolated static let prototypes: [SkeletalType: [String: Double]] = [
        .base:              ["jaw_ratio": 0.830, "chin_angle": 125.0, "aspect": 1.190, "taper": 0.170, "forehead_ratio": 0.858],
        .round:             ["jaw_ratio": 0.817, "chin_angle": 120.0, "aspect": 1.203, "taper": 0.183, "forehead_ratio": 0.853],
        .oval:              ["jaw_ratio": 0.795, "chin_angle": 116.5, "aspect": 1.191, "taper": 0.206, "forehead_ratio": 0.846],
        .invertedTriangle:  ["jaw_ratio": 0.760, "chin_angle": 112.0, "aspect": 1.204, "taper": 0.241, "forehead_ratio": 0.858],
        .long:              ["jaw_ratio": 0.785, "chin_angle": 116.0, "aspect": 1.229, "taper": 0.215, "forehead_ratio": 0.858],
    ]

    private nonisolated static let featureScale: [String: Double] = [
        "jaw_ratio": 0.035,
        "chin_angle": 7.0,
        "aspect": 0.020,
        "taper": 0.040,
        "forehead_ratio": 0.015,
    ]

    private nonisolated static let featureWeight: [String: Double] = [
        "jaw_ratio": 1.8,
        "chin_angle": 1.6,
        "aspect": 1.2,
        "taper": 1.3,
        "forehead_ratio": 0.4,
    ]

    nonisolated static func extractFeatures(_ m: FaceMetrics) -> Features {
        let temple = max(m.faceWidthTemplePx, 1.0)
        let cheek = max(m.faceWidthCheekbonePx, 1.0)
        return Features(
            aspect: m.faceHeightPx / temple,
            cheekToTemple: cheek / temple,
            jawRatio: m.faceWidthJawPx / cheek,
            foreheadRatio: m.foreheadWidthPx / cheek,
            chinAngle: m.chinAngleDeg,
            taper: (cheek - m.faceWidthJawPx) / cheek
        )
    }

    nonisolated static func score(_ f: Features) -> [SkeletalType: Double] {
        let fv: [String: Double] = [
            "jaw_ratio": f.jawRatio,
            "chin_angle": f.chinAngle,
            "aspect": f.aspect,
            "taper": f.taper,
            "forehead_ratio": f.foreheadRatio,
        ]
        var distances: [SkeletalType: Double] = [:]
        for (type, proto) in prototypes {
            var d2 = 0.0
            for (key, center) in proto {
                let scale = featureScale[key] ?? 1.0
                let weight = featureWeight[key] ?? 1.0
                let diff = ((fv[key] ?? 0) - center) / scale
                d2 += weight * diff * diff
            }
            distances[type] = d2
        }
        let sigma2 = 2.5 * 2.5
        var scores: [SkeletalType: Double] = [:]
        for (k, v) in distances {
            scores[k] = exp(-v / (2 * sigma2))
        }
        return scores
    }

    nonisolated static func classify(faceMesh: FaceMesh) -> Result {
        let m = FaceMetricsCalculator.measure(faceMesh: faceMesh)
        let f = extractFeatures(m)
        let scores = score(f)
        let best = scores.max(by: { $0.value < $1.value })?.key ?? .oval
        return Result(type: best, typeLabel: best.label, features: f, scores: scores, metrics: m)
    }
}
