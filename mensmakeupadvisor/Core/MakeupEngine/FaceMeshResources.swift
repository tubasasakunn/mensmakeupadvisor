import Foundation

// FaceMesh が必要とする外部リソースのロードを担当する。
// バンドル内の `face_mesh_tesselation.json` (接続リスト 2556 個) は MediaPipe
// Python ソリューションの FACEMESH_TESSELATION から事前に抽出済み。
// `face_landmarker.task` はバンドル → キャッシュ → CDN の順に解決する。
nonisolated enum FaceMeshResources {
    enum ResourceError: Error {
        case tesselationMissing
        case modelMissing
    }

    nonisolated(unsafe) private static var cachedTesselation: [(Int, Int)] = []
    private static let tesselationLock = NSLock()

    nonisolated static func tesselationConnections() -> [(Int, Int)] {
        (try? loadTesselationConnections()) ?? []
    }

    nonisolated static func loadTesselationConnections() throws -> [(Int, Int)] {
        tesselationLock.lock()
        defer { tesselationLock.unlock() }
        if !cachedTesselation.isEmpty { return cachedTesselation }

        guard let url = Bundle.main.url(forResource: "face_mesh_tesselation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[Int]]
        else {
            throw ResourceError.tesselationMissing
        }
        cachedTesselation = arr.compactMap { pair in
            pair.count == 2 ? (pair[0], pair[1]) : nil
        }
        return cachedTesselation
    }

    nonisolated static func cachedModelPath() -> String? {
        guard let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let target = cache.appendingPathComponent("face_landmarker.task")
        return FileManager.default.fileExists(atPath: target.path) ? target.path : nil
    }

    // Google 公式 CDN から face_landmarker.task をダウンロード (初回のみ)
    nonisolated static func ensureModelDownloaded() async throws -> String {
        if let bundled = Bundle.main.path(forResource: "face_landmarker", ofType: "task") {
            return bundled
        }
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw ResourceError.modelMissing
        }
        let target = cacheDir.appendingPathComponent("face_landmarker.task")
        if FileManager.default.fileExists(atPath: target.path) {
            return target.path
        }
        guard let url = URL(string: "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task") else {
            throw ResourceError.modelMissing
        }
        let (tmp, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tmp, to: target)
        return target.path
    }
}
