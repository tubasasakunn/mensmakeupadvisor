import CoreGraphics
import Foundation
import MediaPipeTasksVision
import UIKit

// MediaPipe FaceLandmarker (478点) を呼び出し、テッセレーション三角形を抽出して
// 中点分割でメッシュを細かくする。
//
// makeup_claude/loadmap/shared/facemesh.py の Python 実装を忠実に移植している。
// 座標系・三角形 ID は target.json のメッシュ番号と一致する。
//
// SPM 依存: `paescebu/SwiftTasksVision` 経由で公式 `MediaPipeTasksVision` xcframework を
// 取り込んでいる (Google 公式は CocoaPods 配布のみだが、このパッケージが daily で同期する)。
final class FaceMesh {
    struct Point: Sendable {
        var x: Double
        var y: Double
        var z: Double
    }

    struct DetectionResult: Sendable {
        var points: [Point]              // 細分化後の頂点 (x,y は正規化 0-1)
        var triangles: [(Int, Int, Int)] // 細分化後の三角形 (頂点インデックス)
        var landmarksPx: [CGPoint]       // 478 個のランドマーク (ピクセル座標)
        var imageWidth: Int
        var imageHeight: Int
    }

    enum FaceMeshError: Error {
        case modelMissing
        case tesselationMissing
        case faceNotDetected
    }

    private let subdivisionLevel: Int
    private var landmarker: FaceLandmarker?

    private var rawPoints: [Point] = []
    private var rawTriangles: [(Int, Int, Int)] = []

    private(set) var points: [Point] = []
    private(set) var triangles: [(Int, Int, Int)] = []
    private(set) var landmarksPx: [CGPoint] = []
    private(set) var imageSize: CGSize = .zero

    private var midpointCache: [Int64: Int] = [:]
    private var reverseCache: [Int: (Int, Int)] = [:]

    init(subdivisionLevel: Int = 1) {
        self.subdivisionLevel = subdivisionLevel
    }

    // MARK: - Init / Detect

    func initialize(modelPath: String? = nil) throws {
        let resolvedPath: String
        if let modelPath, !modelPath.isEmpty {
            resolvedPath = modelPath
        } else if let bundled = Bundle.main.path(forResource: "face_landmarker", ofType: "task") {
            resolvedPath = bundled
        } else if let cached = Self.cachedModelPath() {
            resolvedPath = cached
        } else {
            throw FaceMeshError.modelMissing
        }

        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = resolvedPath
        options.numFaces = 1
        options.runningMode = .image

        landmarker = try FaceLandmarker(options: options)
    }

    @discardableResult
    func detect(image: UIImage) throws -> DetectionResult {
        guard let landmarker else { throw FaceMeshError.modelMissing }

        let mpImage = try MPImage(uiImage: image)
        let result = try landmarker.detect(image: mpImage)
        guard let face = result.faceLandmarks.first else {
            throw FaceMeshError.faceNotDetected
        }

        let w = Int(image.size.width * image.scale)
        let h = Int(image.size.height * image.scale)

        rawPoints = face.map { Point(x: Double($0.x), y: Double($0.y), z: Double($0.z)) }
        landmarksPx = rawPoints.map { CGPoint(x: $0.x * Double(w), y: $0.y * Double(h)) }

        // Tesselation 接続リストを JSON リソースから取得して三角形を組み立てる
        let connections = try Self.loadTesselationConnections()
        rawTriangles = Self.extractTriangles(connections: connections)

        // Working copy
        points = rawPoints
        triangles = rawTriangles
        midpointCache.removeAll(keepingCapacity: true)
        reverseCache.removeAll(keepingCapacity: true)

        // 自動的に subdivide
        for _ in 0..<subdivisionLevel {
            subdivideAll()
        }

        imageSize = CGSize(width: w, height: h)
        return DetectionResult(
            points: points,
            triangles: triangles,
            landmarksPx: landmarksPx,
            imageWidth: w,
            imageHeight: h
        )
    }

    // MARK: - Mesh utilities

    func trianglePixels(triangleID: Int, width: Int, height: Int) -> [CGPoint] {
        guard triangles.indices.contains(triangleID) else { return [] }
        let (a, b, c) = triangles[triangleID]
        return [a, b, c].map { idx in
            let p = points[idx]
            return CGPoint(x: p.x * Double(width), y: p.y * Double(height))
        }
    }

    // OpenCV `cv2.fillPoly(mask, [pts], 1.0)` 相当。
    func buildMask(meshIDs: [Int], width: Int, height: Int) -> MaskBuffer {
        let mask = MaskBuffer(width: width, height: height)
        guard let context = CGContext(
            data: mask.dataPointer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return mask }

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

    // 左右反転メッシュ ID を返す。Python 版 `find_mirror_meshes` と同じ。
    func mirrorMeshes(meshIDs: Set<Int>) -> Set<Int> {
        let mirror = mirrorMap()
        var triMap: [TriKey: Int] = [:]
        triMap.reserveCapacity(triangles.count)
        for (idx, tri) in triangles.enumerated() {
            triMap[TriKey(tri)] = idx
        }

        var result: Set<Int> = []
        for mid in meshIDs where triangles.indices.contains(mid) {
            let (a, b, c) = triangles[mid]
            let key = TriKey((mirror[a], mirror[b], mirror[c]))
            if let id = triMap[key] {
                result.insert(id)
            }
        }
        return result
    }

    // MARK: - Private

    private func midpoint(_ i: Int, _ j: Int) -> Int {
        let key = Int64(min(i, j)) * 100_000 + Int64(max(i, j))
        if let cached = midpointCache[key] { return cached }
        let a = points[i]
        let b = points[j]
        points.append(Point(
            x: (a.x + b.x) / 2,
            y: (a.y + b.y) / 2,
            z: (a.z + b.z) / 2
        ))
        let idx = points.count - 1
        midpointCache[key] = idx
        reverseCache[idx] = (i, j)
        return idx
    }

    private func subdivideAll() {
        var newTris: [(Int, Int, Int)] = []
        newTris.reserveCapacity(triangles.count * 4)
        for (a, b, c) in triangles {
            let mab = midpoint(a, b)
            let mbc = midpoint(b, c)
            let mac = midpoint(a, c)
            newTris.append((a, mab, mac))
            newTris.append((mab, b, mbc))
            newTris.append((mac, mbc, c))
            newTris.append((mab, mbc, mac))
        }
        triangles = newTris
    }

    // Python 版 `_get_mirror_map` と同等。
    private func mirrorMap() -> [Int] {
        let rawN = rawPoints.count
        let total = points.count
        var mirror = Array(0..<total)

        let sumX = (0..<rawN).reduce(0.0) { $0 + points[$1].x }
        let cx = sumX / Double(rawN)
        for i in 0..<rawN {
            let mx = 2 * cx - points[i].x
            let my = points[i].y
            var best = i
            var bestD = Double.greatestFiniteMagnitude
            for j in 0..<rawN {
                let dx = points[j].x - mx
                let dy = points[j].y - my
                let d = dx * dx + dy * dy
                if d < bestD {
                    bestD = d
                    best = j
                }
            }
            mirror[i] = best
        }

        for i in rawN..<total {
            guard let parents = reverseCache[i] else { continue }
            let ma = mirror[parents.0]
            let mb = mirror[parents.1]
            let key = Int64(min(ma, mb)) * 100_000 + Int64(max(ma, mb))
            if let mid = midpointCache[key] {
                mirror[i] = mid
            }
        }
        return mirror
    }

    private static func extractTriangles(connections: [(Int, Int)]) -> [(Int, Int, Int)] {
        var adj: [Int: Set<Int>] = [:]
        for (u, v) in connections {
            adj[u, default: []].insert(v)
            adj[v, default: []].insert(u)
        }

        var result: [(Int, Int, Int)] = []
        var seen: Set<TriKey> = []
        for (u, v) in connections {
            guard let nu = adj[u], let nv = adj[v] else { continue }
            for w in nu where w != v && nv.contains(w) {
                let key = TriKey((u, v, w))
                if seen.insert(key).inserted {
                    result.append((u, v, w))
                }
            }
        }
        return result
    }

    // MARK: - Resources

    // FaceMesh のテッセレーション接続リスト (2556 個) を読み込む。
    // MediaPipe Python ソリューションの FACEMESH_TESSELATION から事前に抽出済みで、
    // バンドル内 `face_mesh_tesselation.json` に格納している。
    private static var cachedTesselation: [(Int, Int)] = []
    private static let tesselationLock = NSLock()

    private static func loadTesselationConnections() throws -> [(Int, Int)] {
        tesselationLock.lock()
        defer { tesselationLock.unlock() }
        if !cachedTesselation.isEmpty { return cachedTesselation }

        guard let url = Bundle.main.url(forResource: "face_mesh_tesselation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let arr = try? JSONSerialization.jsonObject(with: data) as? [[Int]]
        else {
            throw FaceMeshError.tesselationMissing
        }
        cachedTesselation = arr.compactMap { pair in
            pair.count == 2 ? (pair[0], pair[1]) : nil
        }
        return cachedTesselation
    }

    static func cachedModelPath() -> String? {
        guard let cache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let target = cache.appendingPathComponent("face_landmarker.task")
        return FileManager.default.fileExists(atPath: target.path) ? target.path : nil
    }

    // Google 公式 CDN から face_landmarker.task をダウンロード (初回のみ)
    static func ensureModelDownloaded() async throws -> String {
        if let bundled = Bundle.main.path(forResource: "face_landmarker", ofType: "task") {
            return bundled
        }
        guard let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            throw FaceMeshError.modelMissing
        }
        let target = cacheDir.appendingPathComponent("face_landmarker.task")
        if FileManager.default.fileExists(atPath: target.path) {
            return target.path
        }
        guard let url = URL(string: "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task") else {
            throw FaceMeshError.modelMissing
        }
        let (tmp, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.moveItem(at: tmp, to: target)
        return target.path
    }
}

private struct TriKey: Hashable {
    let a: Int
    let b: Int
    let c: Int
    init(_ tri: (Int, Int, Int)) {
        var arr = [tri.0, tri.1, tri.2]
        arr.sort()
        a = arr[0]; b = arr[1]; c = arr[2]
    }
}
