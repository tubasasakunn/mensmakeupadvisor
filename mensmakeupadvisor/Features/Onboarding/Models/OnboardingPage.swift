import Foundation

enum OnboardingPageKind: String {
    case cover, stat, compare, feature, concept, thesis, principle, duo, example, goal, list, howto, cta
}

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

    // cover
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

    // stat
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

    // compare
    static func compare(
        id: Int, tag: String,
        title: String? = nil,
        body: String? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .compare, tag: tag)
        p.title = title; p.body = body
        return p
    }

    // concept
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

    // thesis
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

    // principle
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

    // duo
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

    // example
    static func example(
        id: Int, tag: String,
        title: String? = nil,
        exampleItems: [(concern: String, advice: String)]? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .example, tag: tag)
        p.title = title; p.exampleItems = exampleItems
        return p
    }

    // goal
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

    // list
    static func list(
        id: Int, tag: String,
        title: String? = nil,
        listItems: [(title: String, desc: String)]? = nil
    ) -> OnboardingPage {
        var p = OnboardingPage(id: id, kind: .list, tag: tag)
        p.title = title; p.listItems = listItems
        return p
    }

    // feature
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

    // howto
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

    // cta
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

// Page data is in OnboardingPage+Data.swift
