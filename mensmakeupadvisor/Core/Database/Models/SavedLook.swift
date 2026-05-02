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
        eyebrow: Double = 30
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
    }
}
