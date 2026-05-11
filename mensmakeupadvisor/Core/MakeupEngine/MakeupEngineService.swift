import Foundation
import SwiftUI
import UIKit

// MakeupEngine のメインエントリ。
// 1 回の `prepare(image:)` で顔検出 (FaceMesh) を実行し、
// 後続の `analyze()` (顔判定) と `render(intensity:)` (化粧反映) が
// 同じ FaceMesh インスタンスを再利用するためのキャッシュ層。
//
// FaceMesh の実装は現状 Apple Vision Framework (約 76 点) で、
// MediaPipe SPM 公開時に差し替え予定。
// Studio 画面でスライダーを動かす度に再検出が走らないようにする。
actor MakeupEngineService {
    enum EngineError: Error, LocalizedError {
        case faceNotDetected
        case notPrepared

        var errorDescription: String? {
            switch self {
            case .faceNotDetected: "顔が検出できませんでした"
            case .notPrepared: "解析前です"
            }
        }
    }

    private var mesh: FaceMesh?
    private var sourceImage: UIImage?

    func prepare(image: UIImage) async throws {
        let path = try await FaceMesh.ensureModelDownloaded()
        let newMesh = FaceMesh(subdivisionLevel: 1)
        try newMesh.initialize(modelPath: path)
        do {
            _ = try newMesh.detect(image: image)
        } catch FaceMesh.FaceMeshError.faceNotDetected {
            throw EngineError.faceNotDetected
        }
        self.mesh = newMesh
        self.sourceImage = image
    }

    func analyze() throws -> AnalysisResult {
        guard let mesh else { throw EngineError.notPrepared }
        return FaceScoringEngine.evaluate(faceMesh: mesh)
    }

    func render(intensity: MakeupIntensity,
                selection: MakeupRenderer.LayerSelection = .default) throws -> UIImage {
        guard let mesh, let source = sourceImage else { throw EngineError.notPrepared }
        return MakeupRenderer.render(image: source, faceMesh: mesh,
                                     intensity: intensity, selection: selection)
    }

    func reset() {
        mesh = nil
        sourceImage = nil
    }

    var isPrepared: Bool { mesh != nil }
}

// MARK: - Environment

private struct MakeupEngineServiceKey: EnvironmentKey {
    static let defaultValue = MakeupEngineService()
}

extension EnvironmentValues {
    var makeupEngineService: MakeupEngineService {
        get { self[MakeupEngineServiceKey.self] }
        set { self[MakeupEngineServiceKey.self] = newValue }
    }
}
