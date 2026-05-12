import Foundation

// 2.2.1 顔全体の縦横バランス判定
// makeup_claude/loadmap/2/2.2.1-face-ratio/main.py の `analyze` を移植。
enum FaceRatioJudge {
    // landmark 10 が生え際より下にあるための補正係数
    nonisolated static let foreheadExtend = 1.25
    nonisolated static let irisDiameterMM = 11.7
    nonisolated static let aistMaleHeightCM = 23.2
    nonisolated static let aistMaleWidthCM = 14.5
    nonisolated static let kogaoHeightCM = 20.0
    nonisolated static let kogaoWidthCM = 14.0

    enum RatioName: String, Sendable { case golden, silver, japanese }
    nonisolated static let ratios: [RatioName: Double] = [
        .golden: 1.618, .silver: 1.414, .japanese: 1.460,
    ]

    struct Result: Sendable {
        var faceHeightPxRaw: Double
        var faceHeightPx: Double
        var faceWidthPx: Double
        var aspectRaw: Double
        var aspect: Double
        var losses: [RatioName: Double]
        var closestRatio: RatioName
        var mmPerPixel: Double
        var faceHeightCM: Double
        var faceWidthCM: Double
        var kogaoScore: Double
        var kogaoLabel: String
        var vsAistHeight: Double
        var vsAistWidth: Double
    }

    nonisolated static func analyze(faceMesh: FaceMesh) -> Result {
        let m = FaceMetricsCalculator.measure(faceMesh: faceMesh)

        let raw = m.faceHeightPx
        let height = raw * foreheadExtend
        let width = max(m.faceWidthTemplePx, 1)
        let aspectRaw = raw / width
        let aspect = height / width

        var losses: [RatioName: Double] = [:]
        for (name, target) in ratios {
            losses[name] = abs(aspect - target) / target
        }
        let closest = losses.min(by: { $0.value < $1.value })?.key ?? .japanese

        let irisPx = (m.irisRDiameterPx + m.irisLDiameterPx) / 2.0
        var mmPerPixel = 0.0
        var heightCM = 0.0
        var widthCM = 0.0
        if irisPx > 1e-3 {
            mmPerPixel = irisDiameterMM / irisPx
            heightCM = height * mmPerPixel / 10.0
            widthCM = width * mmPerPixel / 10.0
        }

        var kogaoScore = 0.0
        var kogaoLabel = ""
        var vsHeight = 0.0
        var vsWidth = 0.0
        if heightCM > 0, widthCM > 0 {
            let hScore = max(0, min(100, kogaoHeightCM / heightCM * 100))
            let wScore = max(0, min(100, kogaoWidthCM / widthCM * 100))
            kogaoScore = (hScore + wScore) / 2
            switch kogaoScore {
            case 95...: kogaoLabel = "Very Small (+)"
            case 85..<95: kogaoLabel = "Small"
            case 75..<85: kogaoLabel = "Average"
            default: kogaoLabel = "Large"
            }
            vsHeight = heightCM / aistMaleHeightCM
            vsWidth = widthCM / aistMaleWidthCM
        }

        return Result(
            faceHeightPxRaw: raw, faceHeightPx: height, faceWidthPx: width,
            aspectRaw: aspectRaw, aspect: aspect, losses: losses, closestRatio: closest,
            mmPerPixel: mmPerPixel, faceHeightCM: heightCM, faceWidthCM: widthCM,
            kogaoScore: kogaoScore, kogaoLabel: kogaoLabel,
            vsAistHeight: vsHeight, vsAistWidth: vsWidth
        )
    }
}
