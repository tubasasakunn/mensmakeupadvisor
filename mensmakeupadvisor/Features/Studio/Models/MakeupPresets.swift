import Foundation

// target.json の area name を「人が読める短いラベル」に変換するテーブル。
// FINE TUNE の選択チップに表示する用途。
nonisolated enum MakeupAreaLabel {
    nonisolated static func display(_ areaName: String) -> String {
        switch areaName {
        // highlight
        case "base_t-zone":     return "T-ZONE"
        case "base_c-zone":     return "C-ZONE"
        case "base_under-eye":  return "目下"
        case "base_megasira":   return "目頭"
        case "base_zintyuu":    return "人中"
        case "marugao_t-zone":  return "丸 T"
        case "marugao_c-zone":  return "丸 C"
        case "marugao_ago":     return "顎先"
        case "omonaga_t-zone":  return "面 T"
        case "omonaga_c-zone":  return "面 C"
        // shadow
        case "omonaga-upper":   return "額"
        case "omonaga-lower":   return "顎"
        case "marugao-side":    return "頬輪郭"
        // eye
        case "eyeshadow_base":   return "ベース"
        case "eyeshadow_crease": return "クリーズ"
        case "tear_bag":         return "涙袋"
        case "lower_outer":      return "下まぶた"
        case "eyeliner":         return "ライナー"
        default: return areaName.uppercased()
        }
    }
}

// 顔判定結果から各 layer の「最初にチェックされているエリア集合」を返す。
// Studio に入る前に決まり、ユーザーが一度でも触ったら以降は上書きしない。
nonisolated enum MakeupAreaDefaults {
    nonisolated static func highlight(for shape: FaceShape?) -> Set<String> {
        switch shape ?? .tamago {
        case .tamago, .gyaku, .base:
            return Set(MeshAreaLibrary.areas(category: .highlight, prefix: "base").map(\.name))
        case .marugao:
            return Set(MeshAreaLibrary.areas(category: .highlight, prefix: "marugao").map(\.name))
        case .omonaga:
            return Set(MeshAreaLibrary.areas(category: .highlight, prefix: "omonaga").map(\.name))
        }
    }
    nonisolated static func shadow(for shape: FaceShape?) -> Set<String> {
        switch shape ?? .tamago {
        case .tamago:
            return Set(MeshAreaLibrary.areas(category: .shadow, prefix: "omonaga").map(\.name))
                .union(MeshAreaLibrary.areas(category: .shadow, prefix: "marugao").map(\.name))
        case .marugao:
            return Set(MeshAreaLibrary.areas(category: .shadow, prefix: "marugao").map(\.name))
        case .omonaga:
            return Set(MeshAreaLibrary.areas(category: .shadow, prefix: "omonaga").map(\.name))
        case .gyaku:
            return Set(MeshAreaLibrary.areas(category: .shadow, prefix: "marugao").map(\.name))
        case .base:
            return Set(MeshAreaLibrary.areas(category: .shadow, prefix: "omonaga").map(\.name))
        }
    }
    nonisolated static func eye(for shape: FaceShape?) -> Set<String> {
        // 顔型に関わらず eyeshadow_base / crease / tear_bag / lower_outer の 4 つを既定。
        ["eyeshadow_base", "eyeshadow_crease", "tear_bag", "lower_outer"]
    }
}
