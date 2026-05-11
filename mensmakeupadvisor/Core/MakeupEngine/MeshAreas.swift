import Foundation

// target.json の各カテゴリ。
// makeup_claude の mesh_id は `subdivision_level = 1` のメッシュ番号と一致する。
enum MeshAreaCategory: String, CaseIterable, Sendable {
    case highlight
    case shadow
    case eye
    case eyebrow
}

struct MeshArea: Sendable, Hashable {
    let name: String
    let meshIDs: [Int]
}

// target.json をロードしてカテゴリ → エリア辞書を返す。
//
// Python 版 (`loadmap/1-virtual-makeup/1-1-highlight/main.py:load_target_areas`)
// と同じく、過去のデータで mesh_id が `[[...]]` の二重リストになっていたケースを
// 吸収する。
enum MeshAreaLibrary {
    nonisolated static func load(category: MeshAreaCategory, bundle: Bundle = .main) -> [MeshArea] {
        guard let url = bundle.url(forResource: "target", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entries = json[category.rawValue] as? [[String: Any]]
        else {
            return []
        }

        var result: [MeshArea] = []
        result.reserveCapacity(entries.count)
        for entry in entries {
            guard let name = entry["name"] as? String else { continue }
            let ids: [Int]
            if let flat = entry["mesh_id"] as? [Int] {
                ids = flat
            } else if let nested = entry["mesh_id"] as? [[Int]], let inner = nested.first {
                ids = inner
            } else {
                continue
            }
            result.append(MeshArea(name: name, meshIDs: ids))
        }
        return result
    }

    nonisolated static func lookup(category: MeshAreaCategory, name: String, bundle: Bundle = .main) -> MeshArea? {
        load(category: category, bundle: bundle).first { $0.name == name }
    }

    nonisolated static func areas(category: MeshAreaCategory, prefix: String, bundle: Bundle = .main) -> [MeshArea] {
        load(category: category, bundle: bundle).filter { $0.name.hasPrefix(prefix) }
    }
}
