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
    // Swift 6 typed throws で「このエンジンが投げる唯一の Error」を表す。
    // 下流の MediaPipe / リソース / ネットワーク由来のエラーは全て下のいずれかへ
    // 寄せる。これで Service レイヤの catch がシンプルになる。
    enum EngineError: Error, LocalizedError {
        case faceNotDetected
        case notPrepared
        case modelUnavailable        // モデルファイルが取れない (バンドル無し+ネットワーク失敗)
        case meshInitializationFailed
        case resourceMissing         // tesselation 等のリソースが無い

        var errorDescription: String? {
            switch self {
            case .faceNotDetected:          "顔が検出できませんでした"
            case .notPrepared:              "解析前です"
            case .modelUnavailable:         "モデルファイルを取得できませんでした"
            case .meshInitializationFailed: "顔メッシュ初期化に失敗しました"
            case .resourceMissing:          "リソースファイルが見つかりません"
            }
        }
    }

    private var mesh: FaceMesh?
    private var sourceImage: UIImage?

    // 1 段目で顔検出 → bbox 周辺で切り抜き → 切り抜いた画像で再検出、までを 1 回の
    // `prepare` で実行する。戻り値は実際に下流 (analyze / render) で使われる
    // 「顔まわりにトリミング済みの」画像。
    @discardableResult
    func prepare(image: UIImage) async throws(EngineError) -> UIImage {
        let path: String
        do {
            path = try await FaceMeshResources.ensureModelDownloaded()
        } catch {
            throw EngineError.modelUnavailable
        }

        let firstMesh = FaceMesh(subdivisionLevel: 1)
        do {
            try firstMesh.initialize(modelPath: path)
        } catch {
            throw EngineError.meshInitializationFailed
        }

        let upright = image.uprightOriented()
        let firstDetection: FaceMesh.DetectionResult
        do {
            firstDetection = try firstMesh.detect(image: upright)
        } catch FaceMesh.FaceMeshError.faceNotDetected {
            throw EngineError.faceNotDetected
        } catch {
            throw EngineError.meshInitializationFailed
        }

        // bbox で顔まわりに切り抜く。元画像と大差ない時は元画像を使う。
        let working: UIImage = FaceCropper.crop(
            image: upright,
            landmarksPx: firstDetection.landmarksPx
        ) ?? upright

        // 切り抜いた画像で再検出し、以降の座標系をクロップ後に揃える。
        // (元画像のままだと Diagnosis / Studio の表示も元のまま広くなる)
        let finalMesh: FaceMesh
        if working === upright {
            finalMesh = firstMesh
        } else {
            finalMesh = FaceMesh(subdivisionLevel: 1)
            do {
                try finalMesh.initialize(modelPath: path)
                _ = try finalMesh.detect(image: working)
            } catch FaceMesh.FaceMeshError.faceNotDetected {
                // 切り抜きで失敗する稀ケースは元画像にフォールバック
                self.mesh = firstMesh
                self.sourceImage = upright
                return upright
            } catch {
                throw EngineError.meshInitializationFailed
            }
        }

        self.mesh = finalMesh
        self.sourceImage = working
        return working
    }

    func analyze() throws(EngineError) -> AnalysisResult {
        guard let mesh else { throw EngineError.notPrepared }
        return FaceScoringEngine.evaluate(faceMesh: mesh)
    }

    func render(composition: MakeupComposition) throws(EngineError) -> UIImage {
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
