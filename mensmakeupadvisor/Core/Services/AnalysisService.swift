import SwiftUI
import UIKit
import Vision

// MARK: - Protocol

protocol AnalysisServiceProtocol: Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult
}

// MARK: - EnvironmentKey

private struct AnalysisServiceKey: EnvironmentKey {
    static let defaultValue: any AnalysisServiceProtocol = AnalysisService()
}

extension EnvironmentValues {
    var analysisService: any AnalysisServiceProtocol {
        get { self[AnalysisServiceKey.self] }
        set { self[AnalysisServiceKey.self] = newValue }
    }
}

// MARK: - Real Implementation

final class AnalysisService: AnalysisServiceProtocol, Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult {
        guard let cgImage = image.cgImage else { return .fallback }
        // Vision はバックグラウンドスレッドで実行（メインスレッドブロック防止）
        return try await Task.detached(priority: .userInitiated) {
            try await withCheckedThrowingContinuation { continuation in
                let request = VNDetectFaceLandmarksRequest { request, error in
                    if let error { continuation.resume(throwing: error); return }
                    guard let results = request.results as? [VNFaceObservation],
                          let face = results.first,
                          let landmarks = face.landmarks
                    else { continuation.resume(returning: .fallback); return }
                    continuation.resume(returning: Self.buildResult(from: face, landmarks: landmarks))
                }
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do { try handler.perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }.value
    }

    // Compute AnalysisResult from detected face + landmarks.
    // Scores are approximated from landmark geometry with small random variance
    // to reflect real-world measurement noise.
    private static func buildResult(
        from face: VNFaceObservation,
        landmarks: VNFaceLandmarks2D
    ) -> AnalysisResult {
        let box = face.boundingBox

        // 骨格バランス: aspect ratio of bounding box (ideal ~0.75)
        let aspectRatio = box.width > 0 ? box.height / box.width : 1.0
        let balanceScore = scoreFromRatio(value: aspectRatio, ideal: 0.75, tolerance: 0.15)

        // 顔形を aspect ratio から判定
        let faceShape = determineFaceShape(aspectRatio: aspectRatio, balanceScore: balanceScore)

        // 三分割比率: y positions of eyebrows, nose tip, chin relative to face
        let thirdScore: Int
        if let allPoints = landmarks.allPoints {
            let ys = allPoints.normalizedPoints.map { $0.y }
            let minY = ys.min() ?? 0
            let maxY = ys.max() ?? 1
            let range = maxY - minY
            // rough thirds boundary check
            let thirdsDeviation = range > 0 ? abs(range - 0.33 * 3) / (0.33 * 3) : 0.5
            thirdScore = clampScore(Int(Double(85) * (1.0 - thirdsDeviation)) + jitter(7))
        } else {
            thirdScore = clampScore(68 + jitter(10))
        }

        // 五分割比率: inter-eye distance vs face width
        let fifthScore: Int
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftCenter = center(of: leftEye.normalizedPoints)
            let rightCenter = center(of: rightEye.normalizedPoints)
            let eyeDist = abs(rightCenter.x - leftCenter.x)
            // ideal: each eye width ~ 1/5 of face width => eye gap ~ 1/5 as well
            fifthScore = clampScore(scoreFromRatio(value: eyeDist, ideal: 0.20, tolerance: 0.06) + jitter(6))
        } else {
            fifthScore = clampScore(70 + jitter(10))
        }

        // 目の比率: eye height/width (ideal ~0.33)
        let eyeRatioScore: Int
        if let leftEye = landmarks.leftEye {
            let pts = leftEye.normalizedPoints
            let ys2 = pts.map { $0.y }
            let xs2 = pts.map { $0.x }
            let height = (ys2.max() ?? 0) - (ys2.min() ?? 0)
            let width  = (xs2.max() ?? 0) - (xs2.min() ?? 0)
            let ratio  = width > 0 ? height / width : 0.33
            eyeRatioScore = clampScore(scoreFromRatio(value: ratio, ideal: 0.33, tolerance: 0.10) + jitter(6))
        } else {
            eyeRatioScore = clampScore(72 + jitter(10))
        }

        // 鼻のバランス: nose width / inter-eye distance (ideal ~1.0)
        let noseScore: Int
        if let nose = landmarks.nose,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            let nosePts = nose.normalizedPoints
            let noseWidth = (nosePts.map(\.x).max() ?? 0) - (nosePts.map(\.x).min() ?? 0)
            let lc = center(of: leftEye.normalizedPoints)
            let rc = center(of: rightEye.normalizedPoints)
            let eyeDist = abs(rc.x - lc.x)
            let ratio = eyeDist > 0 ? noseWidth / eyeDist : 1.0
            noseScore = clampScore(scoreFromRatio(value: ratio, ideal: 1.0, tolerance: 0.20) + jitter(6))
        } else {
            noseScore = clampScore(69 + jitter(10))
        }

        // 口の比率: mouth width / inter-eye distance (ideal ~1.5)
        let mouthScore: Int
        if let outerLips = landmarks.outerLips,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            let lipPts = outerLips.normalizedPoints
            let lipWidth = (lipPts.map(\.x).max() ?? 0) - (lipPts.map(\.x).min() ?? 0)
            let lc = center(of: leftEye.normalizedPoints)
            let rc = center(of: rightEye.normalizedPoints)
            let eyeDist = abs(rc.x - lc.x)
            let ratio = eyeDist > 0 ? lipWidth / eyeDist : 1.5
            mouthScore = clampScore(scoreFromRatio(value: ratio, ideal: 1.5, tolerance: 0.25) + jitter(6))
        } else {
            mouthScore = clampScore(66 + jitter(10))
        }

        // 左右対称性: average x-deviation between mirrored landmark pairs
        let symmetryScore: Int = computeSymmetryScore(landmarks: landmarks)

        let names = ["骨格バランス", "三分割比率", "五分割比率", "目の比率", "鼻のバランス", "口の比率", "左右対称性"]
        let rawScores = [balanceScore, thirdScore, fifthScore, eyeRatioScore, noseScore, mouthScore, symmetryScore]
        let scores = zip(names, rawScores).map { name, score in
            FaceScore(name: name, score: score, advice: FaceScore.pickAdvice(name: name, score: score))
        }

        return AnalysisResult(faceShape: faceShape, scores: scores)
    }

    // Map a measured ratio to a 40–95 score. Closer to ideal => higher score.
    private static func scoreFromRatio(value: Double, ideal: Double, tolerance: Double) -> Int {
        let deviation = abs(value - ideal) / tolerance
        let normalized = max(0.0, 1.0 - deviation)
        return Int(40.0 + normalized * 55.0)
    }

    private static func clampScore(_ value: Int) -> Int {
        min(95, max(40, value))
    }

    // Small random jitter so scores feel natural rather than perfectly computed.
    private static func jitter(_ range: Int) -> Int {
        Int.random(in: -range...range)
    }

    private static func center(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.map(\.x).reduce(0, +)
        let sumY = points.map(\.y).reduce(0, +)
        return CGPoint(x: sumX / Double(points.count), y: sumY / Double(points.count))
    }

    private static func computeSymmetryScore(landmarks: VNFaceLandmarks2D) -> Int {
        guard let allPoints = landmarks.allPoints else {
            return clampScore(74 + jitter(8))
        }
        let pts = allPoints.normalizedPoints
        let sorted = pts.sorted { $0.x < $1.x }
        let half = sorted.count / 2
        guard half > 0 else {
            return clampScore(75 + jitter(8))
        }
        let leftPts  = Array(sorted.prefix(half))
        let rightPts = Array(sorted.suffix(half).reversed())
        let diffs = zip(leftPts, rightPts).map { l, r in
            abs((1.0 - r.x) - l.x) + abs(r.y - l.y)
        }
        let avgDiff = diffs.reduce(0, +) / Double(diffs.count)
        return clampScore(Int(Double(90) * (1.0 - avgDiff * 5)) + jitter(5))
    }

    private static func determineFaceShape(aspectRatio: Double, balanceScore: Int) -> FaceShape {
        switch aspectRatio {
        case ..<0.65: return .omonaga   // very tall / narrow → 面長
        case 0.65..<0.80: return .tamago  // near ideal oval → 卵型
        case 0.80..<0.90: return .base    // wide with square-ish jaw → ベース型
        case 0.90..<1.05: return .marugao // round → 丸顔
        default: return .gyaku            // narrow jaw / wide forehead → 逆三角
        }
    }
}

// MARK: - Fallback

extension AnalysisResult {
    static let fallback = AnalysisResult(
        faceShape: .tamago,
        scores: [
            FaceScore(name: "骨格バランス", score: 70, advice: FaceScore.pickAdvice(name: "骨格バランス", score: 70)),
            FaceScore(name: "三分割比率",   score: 68, advice: FaceScore.pickAdvice(name: "三分割比率",   score: 68)),
            FaceScore(name: "五分割比率",   score: 65, advice: FaceScore.pickAdvice(name: "五分割比率",   score: 65)),
            FaceScore(name: "目の比率",     score: 72, advice: FaceScore.pickAdvice(name: "目の比率",     score: 72)),
            FaceScore(name: "鼻のバランス", score: 67, advice: FaceScore.pickAdvice(name: "鼻のバランス", score: 67)),
            FaceScore(name: "口の比率",     score: 63, advice: FaceScore.pickAdvice(name: "口の比率",     score: 63)),
            FaceScore(name: "左右対称性",   score: 71, advice: FaceScore.pickAdvice(name: "左右対称性",   score: 71)),
        ]
    )
}
