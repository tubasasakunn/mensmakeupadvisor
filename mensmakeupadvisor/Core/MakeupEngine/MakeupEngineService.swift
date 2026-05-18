import Foundation
import SwiftUI
import UIKit

// MakeupEngine のメインエントリ。
// 1 回の `prepare(image:)` で MediaPipe FaceLandmarker を初期化 + 顔検出を実行し、
// 後続の `analyze()` (顔判定) と `render(intensity:)` (化粧反映) が
// 同じ FaceMesh インスタンスを再利用するためのキャッシュ層。
//
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

    // 1 段目で顔検出 → bbox 周辺で切り抜き → 切り抜いた画像で再検出、までを 1 回の
    // `prepare` で実行する。戻り値は実際に下流 (analyze / render) で使われる
    // 「顔まわりにトリミング済みの」画像。
    @discardableResult
    func prepare(image: UIImage) async throws -> UIImage {
        let path = try await FaceMeshResources.ensureModelDownloaded()
        let firstMesh = FaceMesh(subdivisionLevel: 1)
        try firstMesh.initialize(modelPath: path)

        let upright = image.uprightOriented()
        let firstDetection: FaceMesh.DetectionResult
        do {
            firstDetection = try firstMesh.detect(image: upright)
        } catch FaceMesh.FaceMeshError.faceNotDetected {
            throw EngineError.faceNotDetected
        }

        // bbox で顔まわりに切り抜く。元画像と大差ない時は元画像を使う。
        let working: UIImage = FaceCropper.crop(
            image: upright,
            landmarksPx: firstDetection.landmarksPx
        ) ?? upright

        // 切り抜いた画像で再検出し、以降の座標系をクロップ後に揃える。
        // (元画像のままだとは Diagnosis / Studio の表示も元のまま広くなる)
        let finalMesh: FaceMesh
        if working === upright {
            finalMesh = firstMesh
        } else {
            finalMesh = FaceMesh(subdivisionLevel: 1)
            try finalMesh.initialize(modelPath: path)
            do {
                _ = try finalMesh.detect(image: working)
            } catch FaceMesh.FaceMeshError.faceNotDetected {
                // 切り抜きで失敗する稀ケースは元画像にフォールバック
                self.mesh = firstMesh
                self.sourceImage = upright
                return upright
            }
        }

        self.mesh = finalMesh
        self.sourceImage = working
        return working
    }

    func analyze() throws -> AnalysisResult {
        guard let mesh else { throw EngineError.notPrepared }
        return FaceScoringEngine.evaluate(faceMesh: mesh)
    }

    func render(composition: MakeupComposition) throws -> UIImage {
        guard let mesh, let source = sourceImage else { throw EngineError.notPrepared }
        return MakeupRenderer.render(image: source, faceMesh: mesh, composition: composition)
    }

    func reset() {
        mesh = nil
        sourceImage = nil
    }
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
