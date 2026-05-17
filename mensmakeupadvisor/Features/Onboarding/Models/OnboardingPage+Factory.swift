import Foundation

// 13 種類の `OnboardingPageKind` ごとに必要なフィールドだけを受け取る factory 群。
// optional プロパティの bag を全部書かなくて済むようにする。
extension OnboardingPage {
    static func cover(
        id: Int, tag: String,
        chapterNo: String? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .cover, tag: tag)
        p.chapterNo = chapterNo; p.title = title; p.subtitle = subtitle; p.body = body
        return p
    }

    static func stat(
        id: Int, tag: String,
        stat: String? = nil,
        statLabel: String? = nil,
        body: String? = nil,
        source: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .stat, tag: tag)
        p.stat = stat; p.statLabel = statLabel; p.body = body; p.source = source
        return p
    }

    static func compare(
        id: Int, tag: String,
        title: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .compare, tag: tag)
        p.title = title; p.body = body
        return p
    }

    static func concept(
        id: Int, tag: String,
        conceptTitle: String? = nil,
        titleJP: String? = nil,
        body: String? = nil,
        source: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .concept, tag: tag)
        p.conceptTitle = conceptTitle; p.titleJP = titleJP; p.body = body; p.source = source
        return p
    }

    static func thesis(
        id: Int, tag: String,
        title: String? = nil,
        body1: String? = nil,
        highlight: String? = nil,
        body2: String? = nil,
        body3: String? = nil,
        body4: String? = nil,
        body5: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .thesis, tag: tag)
        p.title = title; p.body1 = body1; p.highlight = highlight
        p.body2 = body2; p.body3 = body3; p.body4 = body4; p.body5 = body5
        return p
    }

    static func principle(
        id: Int, tag: String,
        num: String? = nil,
        title: String? = nil,
        body: String? = nil,
        items: [(title: String, desc: String)]? = nil,
        footer: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .principle, tag: tag)
        p.num = num; p.title = title; p.body = body; p.items = items; p.footer = footer
        return p
    }

    static func duo(
        id: Int, tag: String,
        leftLabel: String? = nil, leftJP: String? = nil, leftDesc: String? = nil,
        rightLabel: String? = nil, rightJP: String? = nil, rightDesc: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .duo, tag: tag)
        p.leftLabel = leftLabel; p.leftJP = leftJP; p.leftDesc = leftDesc
        p.rightLabel = rightLabel; p.rightJP = rightJP; p.rightDesc = rightDesc
        return p
    }

    static func example(
        id: Int, tag: String,
        title: String? = nil,
        exampleItems: [(concern: String, advice: String)]? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .example, tag: tag)
        p.title = title; p.exampleItems = exampleItems
        return p
    }

    static func goal(
        id: Int, tag: String,
        title: String? = nil,
        quote: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .goal, tag: tag)
        p.title = title; p.quote = quote; p.body = body
        return p
    }

    static func list(
        id: Int, tag: String,
        title: String? = nil,
        listItems: [(title: String, desc: String)]? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .list, tag: tag)
        p.title = title; p.listItems = listItems
        return p
    }

    static func feature(
        id: Int, tag: String,
        featureNo: String? = nil,
        featureLabel: String? = nil,
        featureLabelJP: String? = nil,
        title: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .feature, tag: tag)
        p.featureNo = featureNo; p.featureLabel = featureLabel; p.featureLabelJP = featureLabelJP
        p.title = title; p.body = body
        return p
    }

    static func howto(
        id: Int, tag: String,
        step: String? = nil,
        title: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .howto, tag: tag)
        p.step = step; p.title = title; p.body = body
        return p
    }

    static func cta(
        id: Int, tag: String,
        title: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .cta, tag: tag)
        p.title = title; p.body = body
        return p
    }
}
