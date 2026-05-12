import CoreGraphics
import Foundation

// `loadmap/shared/face_metrics.py` の Python 実装をそのまま移植。
// FaceMesh 検出済みインスタンスから、距離・角度・比率などを一括算出する。
nonisolated struct FaceMetrics: Sendable {
    // 縦方向
    var faceHeightPx: Double = 0
    var foreheadToBrowPx: Double = 0
    var browToSubnasalPx: Double = 0
    var subnasalToChinPx: Double = 0

    // 横方向
    var faceWidthTemplePx: Double = 0
    var faceWidthCheekbonePx: Double = 0
    var faceWidthJawPx: Double = 0
    var foreheadWidthPx: Double = 0

    // 目
    var eyeWidthRPx: Double = 0
    var eyeWidthLPx: Double = 0
    var eyeHeightRPx: Double = 0
    var eyeHeightLPx: Double = 0
    var eyeInnerGapPx: Double = 0

    // 虹彩
    var irisRDiameterPx: Double = 0
    var irisLDiameterPx: Double = 0

    // 鼻
    var noseLengthPx: Double = 0
    var noseWingWidthPx: Double = 0

    // 口
    var mouthWidthPx: Double = 0
    var upperLipThicknessPx: Double = 0
    var lowerLipThicknessPx: Double = 0
    var philtrumPx: Double = 0

    // あご
    var chinAngleDeg: Double = 0

    // 主要比率
    var faceAspect: Double = 0  // 縦/横 (height/temple)

    // 主要座標 (描画/その他のジャッジで再利用するため保持)
    var foreheadTop: CGPoint = .zero
    var chin: CGPoint = .zero
    var glabella: CGPoint = .zero
    var subnasal: CGPoint = .zero
    var templeR: CGPoint = .zero
    var templeL: CGPoint = .zero
    var cheekboneR: CGPoint = .zero
    var cheekboneL: CGPoint = .zero
    var gonionR: CGPoint = .zero
    var gonionL: CGPoint = .zero
    var foreheadRPoint: CGPoint = .zero
    var foreheadLPoint: CGPoint = .zero
}

nonisolated enum FaceMetricsCalculator {
    nonisolated static func measure(faceMesh: FaceMesh) -> FaceMetrics {
        var m = FaceMetrics()

        let forehead = p(faceMesh, FaceLandmarkID.foreheadTop)
        let chin = p(faceMesh, FaceLandmarkID.chinBottom)
        let glabella = p(faceMesh, FaceLandmarkID.glabella)
        let subnasal = p(faceMesh, FaceLandmarkID.subnasal)

        // --- 縦 ---
        m.faceHeightPx = dist(forehead, chin)
        m.foreheadToBrowPx = abs(glabella.y - forehead.y)
        m.browToSubnasalPx = abs(subnasal.y - glabella.y)
        m.subnasalToChinPx = abs(chin.y - subnasal.y)

        // --- 横 ---
        m.faceWidthTemplePx = dist(p(faceMesh, FaceLandmarkID.templeR), p(faceMesh, FaceLandmarkID.templeL))
        m.faceWidthCheekbonePx = dist(p(faceMesh, FaceLandmarkID.cheekboneR), p(faceMesh, FaceLandmarkID.cheekboneL))
        m.faceWidthJawPx = dist(p(faceMesh, FaceLandmarkID.gonionR), p(faceMesh, FaceLandmarkID.gonionL))
        m.foreheadWidthPx = dist(p(faceMesh, FaceLandmarkID.foreheadR), p(faceMesh, FaceLandmarkID.foreheadL))

        // --- 目 ---
        m.eyeWidthRPx = dist(p(faceMesh, FaceLandmarkID.eyeOuterR), p(faceMesh, FaceLandmarkID.eyeInnerR))
        m.eyeWidthLPx = dist(p(faceMesh, FaceLandmarkID.eyeOuterL), p(faceMesh, FaceLandmarkID.eyeInnerL))
        m.eyeHeightRPx = dist(p(faceMesh, FaceLandmarkID.eyeTopR), p(faceMesh, FaceLandmarkID.eyeBotR))
        m.eyeHeightLPx = dist(p(faceMesh, FaceLandmarkID.eyeTopL), p(faceMesh, FaceLandmarkID.eyeBotL))
        m.eyeInnerGapPx = dist(p(faceMesh, FaceLandmarkID.eyeInnerR), p(faceMesh, FaceLandmarkID.eyeInnerL))

        // 虹彩: 左右方向の最大幅 (Python 版は points[1]-points[3] の距離)
        m.irisRDiameterPx = irisHorizontalSpan(faceMesh: faceMesh, ids: FaceLandmarkID.irisR)
        m.irisLDiameterPx = irisHorizontalSpan(faceMesh: faceMesh, ids: FaceLandmarkID.irisL)

        // --- 鼻 ---
        m.noseLengthPx = abs(subnasal.y - p(faceMesh, FaceLandmarkID.noseRoot).y)
        m.noseWingWidthPx = dist(p(faceMesh, FaceLandmarkID.noseWingR), p(faceMesh, FaceLandmarkID.noseWingL))

        // --- 口 ---
        m.mouthWidthPx = dist(p(faceMesh, FaceLandmarkID.mouthR), p(faceMesh, FaceLandmarkID.mouthL))
        m.upperLipThicknessPx = dist(p(faceMesh, FaceLandmarkID.upperLipTop), p(faceMesh, FaceLandmarkID.upperLipIn))
        m.lowerLipThicknessPx = dist(p(faceMesh, FaceLandmarkID.lowerLipIn), p(faceMesh, FaceLandmarkID.lowerLipBot))
        m.philtrumPx = dist(subnasal, p(faceMesh, FaceLandmarkID.upperLipTop))

        // --- あご角度 ---
        let gr = p(faceMesh, FaceLandmarkID.gonionR)
        let gl = p(faceMesh, FaceLandmarkID.gonionL)
        m.chinAngleDeg = angleDeg(v1: vec(gr, chin), v2: vec(gl, chin))

        // --- 比率 ---
        if m.faceWidthTemplePx > 1e-3 {
            m.faceAspect = m.faceHeightPx / m.faceWidthTemplePx
        }

        // --- 座標保存 ---
        m.foreheadTop = forehead
        m.chin = chin
        m.glabella = glabella
        m.subnasal = subnasal
        m.templeR = p(faceMesh, FaceLandmarkID.templeR)
        m.templeL = p(faceMesh, FaceLandmarkID.templeL)
        m.cheekboneR = p(faceMesh, FaceLandmarkID.cheekboneR)
        m.cheekboneL = p(faceMesh, FaceLandmarkID.cheekboneL)
        m.gonionR = gr
        m.gonionL = gl
        m.foreheadRPoint = p(faceMesh, FaceLandmarkID.foreheadR)
        m.foreheadLPoint = p(faceMesh, FaceLandmarkID.foreheadL)

        return m
    }

    // MARK: - Helpers

    nonisolated static func p(_ fm: FaceMesh, _ idx: Int) -> CGPoint {
        guard fm.landmarksPx.indices.contains(idx) else { return .zero }
        return fm.landmarksPx[idx]
    }

    nonisolated static func dist(_ a: CGPoint, _ b: CGPoint) -> Double {
        let dx = Double(a.x - b.x)
        let dy = Double(a.y - b.y)
        return sqrt(dx * dx + dy * dy)
    }

    nonisolated static func vec(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: a.x - b.x, y: a.y - b.y)
    }

    nonisolated static func angleDeg(v1: CGPoint, v2: CGPoint) -> Double {
        let dot = Double(v1.x * v2.x + v1.y * v2.y)
        let n1 = sqrt(Double(v1.x * v1.x + v1.y * v1.y))
        let n2 = sqrt(Double(v2.x * v2.x + v2.y * v2.y))
        let c = dot / (n1 * n2 + 1e-9)
        return acos(max(-1, min(1, c))) * 180.0 / .pi
    }

    nonisolated static func mean(_ fm: FaceMesh, ids: [Int]) -> CGPoint {
        guard !ids.isEmpty else { return .zero }
        var sx: Double = 0
        var sy: Double = 0
        for i in ids where fm.landmarksPx.indices.contains(i) {
            sx += Double(fm.landmarksPx[i].x)
            sy += Double(fm.landmarksPx[i].y)
        }
        let n = Double(ids.count)
        return CGPoint(x: sx / n, y: sy / n)
    }

    nonisolated static func ratioLoss(value: Double, target: Double) -> Double {
        if abs(target) < 1e-9 { return abs(value) }
        return abs(value - target) / target
    }

    private nonisolated static func irisHorizontalSpan(faceMesh: FaceMesh, ids: [Int]) -> Double {
        guard ids.count >= 4,
              faceMesh.landmarksPx.indices.contains(ids[1]),
              faceMesh.landmarksPx.indices.contains(ids[3])
        else { return 0 }
        return dist(faceMesh.landmarksPx[ids[1]], faceMesh.landmarksPx[ids[3]])
    }
}
