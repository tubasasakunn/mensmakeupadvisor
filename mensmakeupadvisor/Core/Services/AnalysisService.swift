import OSLog
import SwiftUI
import UIKit

private let analysisLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "AnalysisService")

// MARK: - Protocol

protocol AnalysisServiceProtocol: Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult
    // makeup_claude の MakeupEngine を共有するためのフック。
    // モック実装はオプションで何もしない。
    func analyze(image: UIImage, sharedEngine: MakeupEngineService?) async throws -> AnalysisResult
}

extension AnalysisServiceProtocol {
    func analyze(image: UIImage, sharedEngine: MakeupEngineService?) async throws -> AnalysisResult {
        try await analyze(image: image)
    }
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
//
// makeup_claude/loadmap/2 の Python 顔判定群を Swift に移植した
// `FaceScoringEngine` を呼び出す実装。
// MediaPipe FaceLandmarker (478点) を使い、骨格分類 → 7 指標 → 総合スコアを算出する。
// `sharedEngine` が渡された場合は同じインスタンスで顔検出結果をキャッシュし、
// Studio 画面での化粧反映 (`MakeupRenderer`) が再検出を伴わずに走れるようにする。

final class AnalysisService: AnalysisServiceProtocol, Sendable {
    func analyze(image: UIImage) async throws -> AnalysisResult {
        try await analyze(image: image, sharedEngine: nil)
    }

    func analyze(image: UIImage, sharedEngine: MakeupEngineService?) async throws -> AnalysisResult {
        guard image.cgImage != nil else {
            analysisLog.error("analyze: image has no cgImage, returning fallback")
            return .fallback
        }
        let engine = sharedEngine ?? MakeupEngineService()
        let started = Date()
        do {
            try await engine.prepare(image: image)
            let result = try await engine.analyze()
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            analysisLog.notice("analyze: MediaPipe ok in \(ms, privacy: .public)ms — faceShape=\(String(describing: result.faceShape), privacy: .public) total=\(result.totalScore, privacy: .public)")
            return result
        } catch MakeupEngineService.EngineError.faceNotDetected {
            analysisLog.warning("analyze: face not detected, returning fallback")
            return .fallback
        } catch {
            analysisLog.error("analyze: MediaPipe failed — \(String(describing: error), privacy: .public)")
            throw error
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
