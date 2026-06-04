import CoreGraphics
import Vision

// Vision が検出した顔を、並行境界を越えて安全に渡せる Sendable 値に落とし込んだもの。
// VNFaceObservation 自体は Sendable ではないため、検出スレッド上でここに必要な
// 座標だけを抽出してから AsyncStream で MainActor へ渡す。
//
// 座標は全て「画像全体に対する正規化座標 (0...1, 原点は左下＝Vision 既定)」。
// 描画側 (MirrorGuideOverlay) で View 座標へ変換する。
struct FaceObservation: Sendable, Equatable {
    var boundingBox: CGRect
    var leftEye: [CGPoint]
    var rightEye: [CGPoint]
    var nose: [CGPoint]

    var hasFace: Bool { boundingBox != .zero }

    var leftEyeCenter: CGPoint? { Self.centroid(leftEye) }
    var rightEyeCenter: CGPoint? { Self.centroid(rightEye) }
    var noseCenter: CGPoint? { Self.centroid(nose) }

    init(
        boundingBox: CGRect = .zero,
        leftEye: [CGPoint] = [],
        rightEye: [CGPoint] = [],
        nose: [CGPoint] = []
    ) {
        self.boundingBox = boundingBox
        self.leftEye = leftEye
        self.rightEye = rightEye
        self.nose = nose
    }

    init(visionFace face: VNFaceObservation) {
        let box = face.boundingBox
        // VNFaceLandmarkRegion2D.normalizedPoints は boundingBox 相対なので
        // 画像全体の正規化座標へ展開する。
        func region(_ r: VNFaceLandmarkRegion2D?) -> [CGPoint] {
            guard let r else { return [] }
            return r.normalizedPoints.map { p in
                CGPoint(
                    x: box.origin.x + CGFloat(p.x) * box.size.width,
                    y: box.origin.y + CGFloat(p.y) * box.size.height
                )
            }
        }
        let lm = face.landmarks
        self.init(
            boundingBox: box,
            leftEye: region(lm?.leftEye),
            rightEye: region(lm?.rightEye),
            nose: region(lm?.nose)
        )
    }

    private static func centroid(_ points: [CGPoint]) -> CGPoint? {
        guard !points.isEmpty else { return nil }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
