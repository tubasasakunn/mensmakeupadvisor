import CoreGraphics
import Foundation
import UIKit
import Vision

// 顔ランドマーク検出のラッパー。
//
// 当初は makeup_claude (Python) と同じく MediaPipe FaceLandmarker (478点) を
// 使う予定だったが、MediaPipe iOS は SPM 配布がなく CocoaPods 専用のため、
// Apple Vision Framework の VNDetectFaceLandmarksRequest (約 76 点) を
// バックエンドにしている。
//
// FaceMetrics や Scoring 群が必要とする MediaPipe ランドマーク ID
// (10=foreheadTop, 152=chinBottom, ...) には Vision の region から
// 近似マッピングを行うことで、Swift 側のアルゴリズムを変更せず利用できるようにする。
//
// なお triangles は Vision からは取得できない (MediaPipe Tesselation は使えない) ため
// 空のままにし、makeup 反映系 (MakeupRenderer 内の buildMask 経由) は no-op となる。
// MediaPipe SPM が将来公開されたらこのファイルだけを差し替えれば本来の動作になる。
final class FaceMesh {
    struct Point: Sendable {
        var x: Double
        var y: Double
        var z: Double
    }

    struct DetectionResult: Sendable {
        var points: [Point]
        var triangles: [(Int, Int, Int)]
        var landmarksPx: [CGPoint]
        var imageWidth: Int
        var imageHeight: Int
    }

    enum FaceMeshError: Error {
        case modelMissing
        case tesselationMissing
        case faceNotDetected
    }

    private let subdivisionLevel: Int

    private(set) var points: [Point] = []
    private(set) var triangles: [(Int, Int, Int)] = []
    private(set) var landmarksPx: [CGPoint] = []
    private(set) var imageSize: CGSize = .zero

    init(subdivisionLevel: Int = 1) {
        self.subdivisionLevel = subdivisionLevel
    }

    // モデルファイルは Vision バックエンドでは不要だが、API 互換のために残している。
    func initialize(modelPath: String? = nil) throws {
        // no-op for Vision backend
    }

    @discardableResult
    func detect(image: UIImage) throws -> DetectionResult {
        guard let cgImage = image.cgImage else { throw FaceMeshError.faceNotDetected }
        let w = cgImage.width
        let h = cgImage.height

        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        guard let face = (request.results as? [VNFaceObservation])?.first,
              let landmarks = face.landmarks
        else {
            throw FaceMeshError.faceNotDetected
        }

        // 478 点分の配列を 0,0 で埋めてから、Vision の各 region から近似値を流し込む
        landmarksPx = Array(repeating: .zero, count: 478)
        VisionLandmarkMapper.fill(
            landmarksPx: &landmarksPx,
            face: face, landmarks: landmarks,
            imageWidth: w, imageHeight: h
        )

        // 正規化 points は landmarksPx から逆算
        points = landmarksPx.map { p in
            Point(
                x: w > 0 ? Double(p.x) / Double(w) : 0,
                y: h > 0 ? Double(p.y) / Double(h) : 0,
                z: 0
            )
        }
        // MediaPipe テッセレーション三角形は Vision からは復元不能なので空のまま。
        // makeup_claude の target.json メッシュ ID は MediaPipe 専用なので
        // MediaPipe SPM が利用可能になるまで化粧反映は無効化される。
        triangles = []

        imageSize = CGSize(width: w, height: h)
        return DetectionResult(
            points: points, triangles: triangles,
            landmarksPx: landmarksPx,
            imageWidth: w, imageHeight: h
        )
    }

    // MARK: - Mesh utilities (Vision バックエンド時は空動作)

    func trianglePixels(triangleID: Int, width: Int, height: Int) -> [CGPoint] {
        guard triangles.indices.contains(triangleID) else { return [] }
        let (a, b, c) = triangles[triangleID]
        return [a, b, c].map { idx in
            let p = points[idx]
            return CGPoint(x: p.x * Double(width), y: p.y * Double(height))
        }
    }

    func buildMask(meshIDs: [Int], width: Int, height: Int) -> MaskBuffer {
        let mask = MaskBuffer(width: width, height: height)
        guard !triangles.isEmpty,
              let context = CGContext(
                data: mask.dataPointer,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
              )
        else { return mask }
        context.setFillColor(gray: 1.0, alpha: 1.0)
        for mid in meshIDs where triangles.indices.contains(mid) {
            let pts = trianglePixels(triangleID: mid, width: width, height: height)
            guard pts.count == 3 else { continue }
            context.beginPath()
            context.move(to: pts[0])
            context.addLine(to: pts[1])
            context.addLine(to: pts[2])
            context.closePath()
            context.fillPath()
        }
        return mask
    }

    func mirrorMeshes(meshIDs: Set<Int>) -> Set<Int> {
        // Vision バックエンドでは triangles が無いため何も返さない
        []
    }

    // Vision バックエンドではモデルファイル不要。互換のために残置。
    static func ensureModelDownloaded() async throws -> String {
        return ""
    }
}

// MARK: - Vision → MediaPipe ID mapper
//
// makeup_claude の Python コードは MediaPipe 478点を前提に書かれている。
// Apple Vision で得られる ~76 点 (region ベース) を、Python コードが参照する
// MediaPipe ランドマーク ID にマッピングする。
//
// すべての ID を埋めるのは不可能なので、FaceMetricsCalculator が必要とする
// 主要 ID にしぼってフィルする。残りは (0,0) のまま残るが、計測関数は安全に動作する
// (距離・角度は計算可能、極端な比率は出るが NaN にはならない)。
enum VisionLandmarkMapper {
    static func fill(landmarksPx: inout [CGPoint],
                     face: VNFaceObservation,
                     landmarks: VNFaceLandmarks2D,
                     imageWidth: Int, imageHeight: Int) {
        // Vision の正規化座標 (0-1, bottom-left origin) を画像ピクセル (top-left origin) に変換する
        // p.x, p.y は boundingBox 相対 (0-1)。boundingBox 自身も image 全体に対して 0-1 正規化、
        // どちらも Y は下から上向きなので最終的に flip する。
        let box = face.boundingBox
        let imgW = CGFloat(imageWidth)
        let imgH = CGFloat(imageHeight)
        func toPixel(_ p: CGPoint) -> CGPoint {
            let normX = box.origin.x + p.x * box.size.width
            let normY = box.origin.y + p.y * box.size.height
            return CGPoint(x: normX * imgW, y: (1 - normY) * imgH)
        }

        // 各 region から代表点を取り出す
        let allPts = landmarks.allPoints?.normalizedPoints.map(toPixel) ?? []
        let contour = landmarks.faceContour?.normalizedPoints.map(toPixel) ?? []
        let median = landmarks.medianLine?.normalizedPoints.map(toPixel) ?? []
        let leftEye = landmarks.leftEye?.normalizedPoints.map(toPixel) ?? []
        let rightEye = landmarks.rightEye?.normalizedPoints.map(toPixel) ?? []
        let leftBrow = landmarks.leftEyebrow?.normalizedPoints.map(toPixel) ?? []
        let rightBrow = landmarks.rightEyebrow?.normalizedPoints.map(toPixel) ?? []
        let nose = landmarks.nose?.normalizedPoints.map(toPixel) ?? []
        let noseCrest = landmarks.noseCrest?.normalizedPoints.map(toPixel) ?? []
        let outerLips = landmarks.outerLips?.normalizedPoints.map(toPixel) ?? []
        let innerLips = landmarks.innerLips?.normalizedPoints.map(toPixel) ?? []
        let leftPupil = landmarks.leftPupil?.normalizedPoints.map(toPixel) ?? []
        let rightPupil = landmarks.rightPupil?.normalizedPoints.map(toPixel) ?? []

        // contour は下から時計回りで描画されていることが多いが、保険として
        // X/Y の極値を使って主要点を選ぶ。
        func minBy(_ pts: [CGPoint], _ key: (CGPoint) -> Double) -> CGPoint {
            pts.min(by: { key($0) < key($1) }) ?? .zero
        }
        func maxBy(_ pts: [CGPoint], _ key: (CGPoint) -> Double) -> CGPoint {
            pts.max(by: { key($0) < key($1) }) ?? .zero
        }
        func midOf(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
            CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        }

        // ---- 主要 ID マッピング ----
        // 縦軸
        if let medianTop = median.min(by: { $0.y < $1.y }) {
            // Vision の median は鼻〜顎ラインなので一番上が forehead 近似
            landmarksPx[FaceLandmarkID.foreheadTop] = medianTop
        } else if !contour.isEmpty {
            landmarksPx[FaceLandmarkID.foreheadTop] = minBy(contour, { Double($0.y) })
        }
        if let medianBot = median.max(by: { $0.y < $1.y }) {
            landmarksPx[FaceLandmarkID.chinBottom] = medianBot
        } else if !contour.isEmpty {
            landmarksPx[FaceLandmarkID.chinBottom] = maxBy(contour, { Double($0.y) })
        }
        // 眉間 (左右眉頭の平均)
        if let r = rightBrow.last, let l = leftBrow.first {
            landmarksPx[FaceLandmarkID.glabella] = midOf(r, l)
        }
        // 鼻根 / 鼻先 / 鼻下
        if let noseRoot = noseCrest.min(by: { $0.y < $1.y }) {
            landmarksPx[FaceLandmarkID.noseRoot] = noseRoot
        }
        if !nose.isEmpty {
            // nose region の中央 ≈ 鼻先
            let mid = nose[nose.count / 2]
            landmarksPx[FaceLandmarkID.noseTip] = mid
        }
        if let subnasal = nose.max(by: { $0.y < $1.y }) {
            landmarksPx[FaceLandmarkID.subnasal] = subnasal
        }

        // 横軸: faceContour 端点
        if !contour.isEmpty {
            landmarksPx[FaceLandmarkID.templeR] = minBy(contour, { Double($0.x) })
            landmarksPx[FaceLandmarkID.templeL] = maxBy(contour, { Double($0.x) })
            // 頬骨は contour 上 1/3
            let n = contour.count
            if n >= 6 {
                landmarksPx[FaceLandmarkID.cheekboneR] = contour[n / 3]
                landmarksPx[FaceLandmarkID.cheekboneL] = contour[n - 1 - n / 3]
            }
            // エラ (gonion) は contour 2/5 付近
            if n >= 10 {
                landmarksPx[FaceLandmarkID.gonionR] = contour[2 * n / 5]
                landmarksPx[FaceLandmarkID.gonionL] = contour[n - 1 - 2 * n / 5]
                landmarksPx[FaceLandmarkID.jawR] = contour[n / 2 - 1]
                landmarksPx[FaceLandmarkID.jawL] = contour[n / 2 + 1]
                landmarksPx[FaceLandmarkID.lowerJawR] = contour[n / 2 - 1]
                landmarksPx[FaceLandmarkID.lowerJawL] = contour[n / 2 + 1]
            }
            // おでこ横幅 (≒templeより内側)
            landmarksPx[FaceLandmarkID.foreheadR] = minBy(contour, { Double($0.x) })
            landmarksPx[FaceLandmarkID.foreheadL] = maxBy(contour, { Double($0.x) })
        }

        // 目: Vision の eye region は外側→内側で並ぶ (右目は X 小→大、左目は X 大→小)
        if rightEye.count >= 4 {
            let sortedX = rightEye.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.eyeOuterR] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.eyeInnerR] = sortedX.last ?? .zero
            let sortedY = rightEye.sorted { $0.y < $1.y }
            landmarksPx[FaceLandmarkID.eyeTopR] = sortedY.first ?? .zero
            landmarksPx[FaceLandmarkID.eyeBotR] = sortedY.last ?? .zero
        }
        if leftEye.count >= 4 {
            let sortedX = leftEye.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.eyeInnerL] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.eyeOuterL] = sortedX.last ?? .zero
            let sortedY = leftEye.sorted { $0.y < $1.y }
            landmarksPx[FaceLandmarkID.eyeTopL] = sortedY.first ?? .zero
            landmarksPx[FaceLandmarkID.eyeBotL] = sortedY.last ?? .zero
        }
        // 虹彩: pupil の周囲に半径 ~irisR 仮想 5 点を置く
        let irisR: CGFloat = 8 // ピクセル単位の仮想半径
        if let pR = rightPupil.first {
            placeIrisRing(center: pR, radius: irisR, ids: FaceLandmarkID.irisR, into: &landmarksPx)
        }
        if let pL = leftPupil.first {
            placeIrisRing(center: pL, radius: irisR, ids: FaceLandmarkID.irisL, into: &landmarksPx)
        }

        // 鼻
        if !nose.isEmpty {
            let sortedX = nose.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.noseWingR] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.noseWingL] = sortedX.last ?? .zero
            landmarksPx[FaceLandmarkID.noseWingROut] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.noseWingLOut] = sortedX.last ?? .zero
        }

        // 口
        if !outerLips.isEmpty {
            let sortedX = outerLips.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.mouthR] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.mouthL] = sortedX.last ?? .zero
            let sortedY = outerLips.sorted { $0.y < $1.y }
            landmarksPx[FaceLandmarkID.upperLipTop] = sortedY.first ?? .zero
            landmarksPx[FaceLandmarkID.lowerLipBot] = sortedY.last ?? .zero
        }
        if !innerLips.isEmpty {
            let sortedY = innerLips.sorted { $0.y < $1.y }
            landmarksPx[FaceLandmarkID.upperLipIn] = sortedY.first ?? .zero
            landmarksPx[FaceLandmarkID.lowerLipIn] = sortedY.last ?? .zero
        }

        // 眉: Vision の eyebrow region は内側→外側で並ぶことが多い
        if rightBrow.count >= 4 {
            let sortedX = rightBrow.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.browTailR] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.browHeadR] = sortedX.last ?? .zero
            landmarksPx[FaceLandmarkID.browPeakR] = sortedX[sortedX.count / 2]
        }
        if leftBrow.count >= 4 {
            let sortedX = leftBrow.sorted { $0.x < $1.x }
            landmarksPx[FaceLandmarkID.browHeadL] = sortedX.first ?? .zero
            landmarksPx[FaceLandmarkID.browTailL] = sortedX.last ?? .zero
            landmarksPx[FaceLandmarkID.browPeakL] = sortedX[sortedX.count / 2]
        }

        // 眉領域マスク用の補助 ID も近傍値で埋める
        fillEyebrowRegionFallback(landmarksPx: &landmarksPx)

        // それ以外の MediaPipe ID は最寄りの allPts で埋めて NaN 防止
        let known = allPts
        if !known.isEmpty {
            for i in 0..<landmarksPx.count where landmarksPx[i] == .zero {
                // 最寄りの代表点で埋める (allPts の重心)
                let cx = known.map(\.x).reduce(0, +) / CGFloat(known.count)
                let cy = known.map(\.y).reduce(0, +) / CGFloat(known.count)
                landmarksPx[i] = CGPoint(x: cx, y: cy)
            }
        }
    }

    private static func placeIrisRing(center: CGPoint, radius: CGFloat,
                                      ids: [Int],
                                      into landmarksPx: inout [CGPoint]) {
        // Python 版は 5 点 (中心 + 4周) を返す。Vision には 1 点しかないので
        // 中心 + 上下左右の 4 点を仮想配置する。
        let offsets: [CGPoint] = [
            .zero,
            CGPoint(x: -radius, y: 0),
            CGPoint(x: 0, y: -radius),
            CGPoint(x: radius, y: 0),
            CGPoint(x: 0, y: radius),
        ]
        for (i, id) in ids.enumerated() where landmarksPx.indices.contains(id) {
            let off = offsets[min(i, offsets.count - 1)]
            landmarksPx[id] = CGPoint(x: center.x + off.x, y: center.y + off.y)
        }
    }

    private static func fillEyebrowRegionFallback(landmarksPx: inout [CGPoint]) {
        // 眉ポリゴンマスク (1.5 眉メイクで使用) 用の補助 ID。
        // Vision では眉の 6 点しか得られないので、平均値で埋める。
        func avg(_ ids: [Int]) -> CGPoint {
            let valid = ids.compactMap { id -> CGPoint? in
                guard landmarksPx.indices.contains(id) else { return nil }
                let p = landmarksPx[id]
                return p == .zero ? nil : p
            }
            guard !valid.isEmpty else { return .zero }
            let sx = valid.map(\.x).reduce(0, +) / CGFloat(valid.count)
            let sy = valid.map(\.y).reduce(0, +) / CGFloat(valid.count)
            return CGPoint(x: sx, y: sy)
        }
        let rightBrowFallback = avg([FaceLandmarkID.browHeadR, FaceLandmarkID.browPeakR, FaceLandmarkID.browTailR])
        for id in (FaceLandmarkID.rightEyebrowUpper + FaceLandmarkID.rightEyebrowLower)
        where landmarksPx.indices.contains(id) && landmarksPx[id] == .zero {
            landmarksPx[id] = rightBrowFallback
        }
        let leftBrowFallback = avg([FaceLandmarkID.browHeadL, FaceLandmarkID.browPeakL, FaceLandmarkID.browTailL])
        for id in (FaceLandmarkID.leftEyebrowUpper + FaceLandmarkID.leftEyebrowLower)
        where landmarksPx.indices.contains(id) && landmarksPx[id] == .zero {
            landmarksPx[id] = leftBrowFallback
        }
    }
}
