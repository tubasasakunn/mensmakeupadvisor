import Foundation

// target.json の area name を「人が読める短いラベル」に変換するテーブル。
// チューニング画面の選択チップに表示する用途。
nonisolated enum MakeupAreaLabel {
    nonisolated static func display(_ areaName: String) -> String {
        switch areaName {
        // highlight
        case "base_t-zone":     return "Tゾーン（額・鼻筋）"
        case "base_c-zone":     return "Cゾーン（頬骨）"
        case "base_under-eye":  return "目の下"
        case "base_megasira":   return "目頭"
        case "base_zintyuu":    return "鼻の下"
        case "marugao_t-zone":  return "Tゾーン（丸顔）"
        case "marugao_c-zone":  return "Cゾーン（丸顔）"
        case "marugao_ago":     return "あご先"
        case "omonaga_t-zone":  return "Tゾーン（面長）"
        case "omonaga_c-zone":  return "Cゾーン（面長）"
        // shadow
        case "omonaga-upper":   return "額のシェード"
        case "omonaga-lower":   return "あごのシェード"
        case "marugao-side":    return "頬の輪郭"
        // eye
        case "eyeshadow_base":   return "まぶた全体"
        case "eyeshadow_crease": return "二重ライン"
        case "tear_bag":         return "涙袋"
        case "lower_outer":      return "下まぶた外側"
        case "eyeliner":         return "アイライン"
        default: return areaName
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
