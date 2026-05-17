import Foundation

enum OnboardingPageKind: String {
    case cover, stat, compare, feature, concept, thesis, principle, duo, example, goal, list, howto, cta
}

// Onboarding は 13 種類のレイアウトを 53 ページに散らす構成。各 kind が
// 必要とするフィールドだけが入った optional プロパティの bag になっている。
// 章ごとのデータは `OnboardingPage+Ch01_04.swift` / `OnboardingPage+Ch05_08.swift`、
// factory メソッド群は `OnboardingPage+Factory.swift` を参照。
struct OnboardingPage: Identifiable {
    let id: Int
    let kind: OnboardingPageKind
    let tag: String
    var chapterNo: String?
    var title: String?
    var subtitle: String?
    var body: String?
    var stat: String?
    var statLabel: String?
    var source: String?
    var conceptTitle: String?
    var titleJP: String?
    var highlight: String?
    var body1: String?
    var body2: String?
    var body3: String?
    var body4: String?
    var body5: String?
    var num: String?
    var items: [(title: String, desc: String)]?
    var footer: String?
    var leftLabel: String?
    var leftJP: String?
    var leftDesc: String?
    var rightLabel: String?
    var rightJP: String?
    var rightDesc: String?
    var exampleItems: [(concern: String, advice: String)]?
    var quote: String?
    var featureNo: String?
    var featureLabel: String?
    var featureLabelJP: String?
    var listItems: [(title: String, desc: String)]?
    var step: String?

    static var all: [OnboardingPage] { ch01_04 + ch05_08 }
}
