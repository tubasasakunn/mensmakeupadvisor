import Foundation
import SwiftData

@Model
final class SavedLook {
    var id: String
    var createdAt: Date
    var presetID: String?
    var totalScore: Int
    var faceShape: String
    var base: Double
    var highlight: Double
    var shadow: Double
    var eye: Double
    var eyebrow: Double

    // どのゾーンが ON だったかを保存する。Archive のメッシュサムネで
    // 「どこに化粧を入れたか」を視覚化するのに使う。CSV 形式は SwiftData
    // (旧マイグレーション) 互換のため。
    var highlightAreasCSV: String = ""
    var shadowAreasCSV: String = ""
    var eyeAreasCSV: String = ""
    var eyebrowTypeRaw: String? = nil

    init(
        id: String = UUID().uuidString,
        createdAt: Date = .now,
        presetID: String? = nil,
        totalScore: Int = 0,
        faceShape: String = "",
        base: Double = 25,
        highlight: Double = 20,
        shadow: Double = 18,
        eye: Double = 18,
        eyebrow: Double = 30,
        highlightAreas: Set<String> = [],
        shadowAreas: Set<String> = [],
        eyeAreas: Set<String> = [],
        eyebrowTypeRaw: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.presetID = presetID
        self.totalScore = totalScore
        self.faceShape = faceShape
        self.base = base
        self.highlight = highlight
        self.shadow = shadow
        self.eye = eye
        self.eyebrow = eyebrow
        self.highlightAreasCSV = highlightAreas.sorted().joined(separator: ",")
        self.shadowAreasCSV = shadowAreas.sorted().joined(separator: ",")
        self.eyeAreasCSV = eyeAreas.sorted().joined(separator: ",")
        self.eyebrowTypeRaw = eyebrowTypeRaw
    }

    var highlightAreaSet: Set<String> {
        highlightAreasCSV.isEmpty ? [] : Set(highlightAreasCSV.split(separator: ",").map(String.init))
    }
    var shadowAreaSet: Set<String> {
        shadowAreasCSV.isEmpty ? [] : Set(shadowAreasCSV.split(separator: ",").map(String.init))
    }
    var eyeAreaSet: Set<String> {
        eyeAreasCSV.isEmpty ? [] : Set(eyeAreasCSV.split(separator: ",").map(String.init))
    }
}
