import Foundation

// Tutorial の 1 ステップ。レイヤー (base / highlight / shadow / eye / eyebrow) +
// 部位 (area name / 眉 type) の組み合わせで「1 ステップ = 1 ゾーン」を表す。
// 顔型ごとに、その人に提案するゾーンだけを並べる。
struct TutorialStep: Identifiable, Sendable {
    let id: String
    let tag: String
    let layer: MakeupLayer
    // area name (target.json の name) or eyebrow type rawValue。base ステップは nil。
    let areaName: String?
    let titleJP: String
    // パーソナライズされた効果説明 (顔型ごとに違う本文)
    let explanation: String
    let oneLiner: String

    // 顔型に応じた tutorial シーケンス。tag は出現順で振り直す。
    static func sequence(for shape: FaceShape?) -> [TutorialStep] {
        let f = shape ?? .tamago
        var steps: [TutorialStep] = []
        steps.append(TutorialStepFactory.baseStep(for: f))
        steps.append(contentsOf: TutorialStepFactory.highlightSteps(for: f))
        steps.append(contentsOf: TutorialStepFactory.shadowSteps(for: f))
        steps.append(contentsOf: TutorialStepFactory.eyeSteps(for: f))
        steps.append(TutorialStepFactory.browStep(for: f))
        return steps.enumerated().map { idx, s in
            TutorialStep(id: s.id, tag: romanNumeral(idx + 1), layer: s.layer,
                         areaName: s.areaName, titleJP: s.titleJP,
                         explanation: s.explanation, oneLiner: s.oneLiner)
        }
    }

    private static func romanNumeral(_ n: Int) -> String {
        let romans = ["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV"]
        return n <= romans.count ? romans[n - 1] : "\(n)"
    }
}
