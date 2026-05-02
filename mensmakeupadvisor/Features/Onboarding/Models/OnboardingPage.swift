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

// MARK: - All Pages

extension OnboardingPage {
    static var all: [OnboardingPage] {
        [
            // ─────────────────────────────────────────────
            // CHAPTER 01: 共感
            // ─────────────────────────────────────────────

            // Page 0 — cover: Chapter 01
            .cover(
                id: 0, tag: "CHAPTER 01",
                chapterNo: "01",
                title: "鏡を見るたび、\n何かが惜しい。",
                subtitle: "A familiar feeling",
                body: "太ってないし、不潔でもない。\nでも「整ってる」とも、ちょっと違う。\n\nその「あと一歩」の正体を、\n言語化するところから始めます。"
            ),

            // Page 1 — stat: 55%
            .stat(
                id: 1, tag: "FACT NO. 01",
                stat: "55%",
                statLabel: "見た目が、\n第一印象を決める比率",
                body: "人が誰かと初対面で会ったとき、\n話の中身より顔と表情のほうが、\nずっと強く印象に残る。\n\n― 世の中はそういうふうに動いている。",
                source: "出典: Mehrabian, UCLA (1971)"
            ),

            // Page 2 — stat: 0.1秒
            .stat(
                id: 2, tag: "FACT NO. 02",
                stat: "0.1秒",
                statLabel: "相手があなたを\n値踏みするまでの時間",
                body: "挨拶する前に、もう判定は終わっている。\n\n挽回するには、その後ずっと話し続けるしかない。\n― 最初の0.1秒が、いちばん安く効く投資。",
                source: "出典: Willis & Todorov, Princeton (2006)"
            ),

            // Page 3 — stat: 71.9%
            .stat(
                id: 3, tag: "FACT NO. 03",
                stat: "71.9%",
                statLabel: "20代男性のうち、\n美容に興味がある人の割合",
                body: "「気にはなるけど、何から手を出せばいいか分からない」\n― そう答えた人の数。\n\nあなたは、孤独な変人ではありません。",
                source: "出典: ホットペッパービューティーアカデミー (2023)"
            ),

            // Page 4 — stat: 3,000回（追加）
            .stat(
                id: 4, tag: "FACT NO. 04",
                stat: "3,000回",
                statLabel: "鏡を見る回数",
                body: "1日あたりの平均回数。\n\n毎日3,000回、自分の顔を見ている。\nその度に「まあいいか」で終わるか、\n「いい感じだ」と思えるか―\nどちらがいいかは、言うまでもない。",
                source: "出典: 研究推計"
            ),

            // Page 5 — stat: 7年（追加）
            .stat(
                id: 5, tag: "FACT NO. 05",
                stat: "7年",
                statLabel: "清潔感のある外見で\n得する時間",
                body: "キャリアと恋愛を含めると\n7年分のアドバンテージ。\n\n外見への投資は、時間をかけて\n確実にリターンが返ってくる。",
                source: "出典: Hamermesh (2011)"
            ),

            // Page 6 — compare
            .compare(
                id: 6, tag: "A QUICK DEMO",
                title: "同じ顔で、\n印象は変えられる。",
                body: "スライダーを左右に動かしてみてください。\n足してるんじゃない、整えてるだけ。"
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 02: なぜやるか
            // ─────────────────────────────────────────────

            // Page 7 — cover: Chapter 02
            .cover(
                id: 7, tag: "CHAPTER 02",
                chapterNo: "02",
                title: "これは「身嗜み」で、\n「化粧」じゃない。",
                subtitle: "A reframe",
                body: "ヒゲを剃るのと、同じ層の話。\nやってない人が、\nやってる人より評価される時代は、\nもう終わりつつあります。"
            ),

            // Page 8 — concept: The Halo.
            .concept(
                id: 8, tag: "WHY 01",
                conceptTitle: "The Halo.",
                titleJP: "ハロー効果",
                body: "見た目が整っている人は、\n仕事の能力や人柄まで\n「なんとなく良さそう」と判断される。\n\n不公平だけど、これは事実。\nだったら、こっち側に立っておく。",
                source: "— Thorndike (1920) ほか多数で再現"
            ),

            // Page 9 — concept: The Mirror.
            .concept(
                id: 9, tag: "WHY 02",
                conceptTitle: "The Mirror.",
                titleJP: "鏡の効果",
                body: "鏡に映る自分が、ちょっと良くなる。\nそれだけで、姿勢が変わる。声が変わる。\n人と目を合わせる回数が増える。\n\n顔を変えると、行動が変わる。\n行動が変わると、結果が変わる。",
                source: "— Bandura (1977) 自己効力感"
            ),

            // Page 10 — concept: The Wage Gap.（追加）
            .concept(
                id: 10, tag: "WHY 03",
                conceptTitle: "The Wage Gap.",
                titleJP: "外見プレミアム",
                body: "外見が上位20%にいる人は、\n下位20%より13%高い年収を得ている。\n\nこれは学歴の差よりも大きい。",
                source: "— Hamermesh, Daniel S. \"Beauty Pays\" (2011)"
            ),

            // Page 11 — concept: The Confidence Loop.（追加）
            .concept(
                id: 11, tag: "WHY 04",
                conceptTitle: "The Confidence Loop.",
                titleJP: "自信の連鎖",
                body: "見た目が良くなると自信が出る。\n自信があると声が大きくなる。\n声が大きい人は説得力がある。\n説得力がある人の評価が上がる。\n―評価が上がると、また自信が増す。",
                source: "— Carney et al., Columbia (2010)"
            ),

            // Page 12 — stat: 38%（追加）
            .stat(
                id: 12, tag: "FACT NO. 06",
                stat: "38%",
                statLabel: "交際相手の外見を\n「重視する」と答えた男性の割合",
                body: "同じ質問で女性は42%。\n\nつまり、外見が「気にならない」人のほうが少数派。\n相手のことを気にするなら、\n自分のことも気にしていいはずです。",
                source: "出典: マッチングアプリ調査 (2023)"
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 03: 理論
            // ─────────────────────────────────────────────

            // Page 13 — cover: Chapter 03
            .cover(
                id: 13, tag: "CHAPTER 03",
                chapterNo: "03",
                title: "メイクには、\nちゃんと理屈がある。",
                subtitle: "Not a vibe",
                body: "気合いやセンスの話じゃない。\n「なぜ、そこに、それを置くのか」\n― 全部、説明できる。\n\nだから、覚えれば誰でも再現できる。"
            ),

            // Page 14 — principle: 00
            .principle(
                id: 14, tag: "BEFORE WE START",
                num: "00",
                title: "先に、\n二つだけ確認。",
                body: "メイクを始める前に、\nこの二つは押さえておいてください。",
                items: [
                    (title: "① まずスキンケアを最低限やる",
                     desc: "メンズメイクは、足すよりも「ノイズを消す」のが本体。土台が荒れていると、何を塗ってもごまかしきれない。洗顔と保湿だけでいい。"),
                    (title: "② 体型をある程度整える",
                     desc: "メイクは骨格の上に成立する技術。顔に骨の凹凸が出ていないと、影を入れる場所がない。痩せろとは言わないが、輪郭は出ていてほしい。")
                ]
            ),

            // Page 15 — thesis
            .thesis(
                id: 15, tag: "THE ONE-LINE THEORY",
                title: "メイクとは、",
                body1: "自分のタイプの中で「いちばん整った顔」の",
                highlight: "バランス",
                body2: "に、",
                body3: "光と影",
                body4: "を使って",
                body5: "近づけていく作業。"
            ),

            // Page 16 — principle: I
            .principle(
                id: 16, tag: "CORE · 1",
                num: "I",
                title: "顔には、\n「整って見える比率」がある。",
                body: "いわゆる黄金比、三分割法、五分割法。\n難しい名前がついてるけど、要は\n「人がパッと見て整ってると感じるバランス」のこと。\n\n一つだけが正解じゃなく、\n顔のタイプごとに、それぞれの正解がある。"
            ),

            // Page 17 — principle: II
            .principle(
                id: 17, tag: "CORE · 2",
                num: "II",
                title: "目指すのは、\nあなたの最良版。",
                body: "別人になろうとすると、必ず失敗する。\n骨格の違う人の顔を真似ても、それはコスプレ。\n\n自分のタイプの中で\n「いちばん整った顔」を目指すのが、\n最短で、いちばん効く。"
            ),

            // Page 18 — principle: III
            .principle(
                id: 18, tag: "CORE · 3",
                num: "III",
                title: "使う道具は、\n光と影だけ。",
                body: "骨は動かせない。顔の幅も変えられない。\nでも「そう見える」ようには、できる。\n\n明るくしたところは前に出てくる。\n暗くしたところは引っ込んで見える。\n― これだけで、顔のバランスは作り変えられる。"
            ),

            // Page 19 — principle: IV（追加）
            .principle(
                id: 19, tag: "CORE · 4",
                num: "IV",
                title: "あなたの「顔タイプ」を知る",
                body: "同じ技を使っても、顔のタイプが違えば結果は変わる。\n本アプリはAIであなたの顔タイプを判定し、\nそのタイプに合った補正の順序と強度を提案します",
                items: [
                    (title: "卵型",
                     desc: "日本人に多い。バランスが良く、ほとんどの技が使える。"),
                    (title: "面長",
                     desc: "縦に長い印象。横に広く見せる技が有効。"),
                    (title: "丸顔",
                     desc: "縦に長く見せる技と、輪郭のシェーディングが中心。"),
                    (title: "ベース型",
                     desc: "エラが張っている。フェイスラインのシェーディングが最重要。")
                ]
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 04: 光と影
            // ─────────────────────────────────────────────

            // Page 20 — cover: Chapter 04
            .cover(
                id: 20, tag: "CHAPTER 04",
                chapterNo: "04",
                title: "結局、\n光と影。",
                subtitle: "That is all",
                body: "名前のついた技は山ほどあるけど、\nやってることは全部、\n「明るくする」か「暗くする」かのどっちか。\n\nここを掴めば、もう迷わない。"
            ),

            // Page 21 — duo
            .duo(
                id: 21, tag: "THE TWO TOOLS",
                leftLabel: "Light",
                leftJP: "明るくする = 前に出す",
                leftDesc: "人の目は明るい方を先に見る。\nそして「こっちが手前」だと感じる。\n\nつまり、明るくすると\nそこは「大きく・近く」見える。",
                rightLabel: "Shadow",
                rightJP: "暗くする = 奥に引っ込める",
                rightDesc: "暗いところは、目が後回しにする。\nそして「奥にある」と感じる。\n\nつまり、暗くすると\nそこは「小さく・遠く」見える。"
            ),

            // Page 22 — example
            .example(
                id: 22, tag: "HOW TO USE IT",
                title: "具体的に、こう使う",
                exampleItems: [
                    (concern: "目と目が、近すぎる気がする",
                     advice: "目頭の内側に「明るく」入れる。すると目頭が前に来て、目の間が広がって見える。"),
                    (concern: "目と目が、離れすぎている気がする",
                     advice: "逆に目頭に「暗く」入れる。すると目頭が奥に下がって、目の間が詰まって見える。")
                ]
            ),

            // Page 23 — example: もっと具体的に（追加）
            .example(
                id: 23, tag: "MORE EXAMPLES",
                title: "もっと具体的に",
                exampleItems: [
                    (concern: "頬が丸く、顔が大きく見える",
                     advice: "頬骨の下から顎に向けて「影」を入れる。顔の余白が引き締まり、小顔効果が出る。"),
                    (concern: "鼻が低く、のっぺりして見える",
                     advice: "鼻筋に細く「光」を入れ、鼻の両側に「影」を入れる。立体感が出て、鼻が高く見える。"),
                    (concern: "おでこが広すぎる気がする",
                     advice: "前髪の生え際と眉の間に「影」を入れる。おでこの面積が視覚的に縮まる。")
                ]
            ),

            // Page 24 — principle: +
            .principle(
                id: 24, tag: "BONUS",
                num: "+",
                title: "色も、\n結局は光と影の仲間。",
                body: "色を別の魔法だと思わなくていい。\n光と影の延長線上にある、というだけ。",
                items: [
                    (title: "赤やオレンジ ＝「光」と同じ働き",
                     desc: "見た目に前に出てくる色。血色を足したい場所、目立たせたい場所に使う。"),
                    (title: "青やグレー ＝「影」と同じ働き",
                     desc: "見た目に引っ込んで見える色。青ヒゲを消すのも、原理はこれ（青を打ち消す肌色を上に乗せる）。")
                ],
                footer: "ただし、男性の顔で派手な色を使うと気づかれやすいので、本アプリではデフォルトで最小限に抑えています。"
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 05: 男性特有
            // ─────────────────────────────────────────────

            // Page 25 — cover: Chapter 05
            .cover(
                id: 25, tag: "CHAPTER 05",
                chapterNo: "05",
                title: "男のメイクは、\n「気づかれない」が前提。",
                subtitle: "Quietly is enough",
                body: "盛るのではなく、整える。\n気づかれずに効かせる ―\nそれが、いちばん長く続いて、\nいちばんリターンが大きい。"
            ),

            // Page 26 — principle: Rule 01
            .principle(
                id: 26, tag: "RULE 01",
                num: "·",
                title: "「気づかれない範囲」を\nデフォルトにする。",
                body: "周りに「化粧してる」と思われずに効かせると、\n使える道具が自然に絞られてくる。\n\nこのアプリは、主にこの2つを使います。",
                items: [
                    (title: "主に使う：光と影（ベージュ・茶系）",
                     desc: "肌が自然に作る陰影と区別がつかない色。「もともとこういう顔」と思われたまま、印象だけが良くなる。"),
                    (title: "控えめに使う：はっきりした色（赤チーク・色付きリップ）",
                     desc: "足したことが見た目でわかりやすい。使ってはいけないわけじゃないが、デフォルトでは検出されにくい色に寄せている。")
                ]
            ),

            // Page 27 — principle: Rule 02
            .principle(
                id: 27, tag: "RULE 02",
                num: "··",
                title: "一度に、やりすぎない。",
                body: "一箇所ずつは自然に見えても、\n顔中ぜんぶ補正すると総量で違和感が出る。\n「差し引きの設計」を意識すると、仕上がりが変わります。",
                items: [
                    (title: "全部を同時にやろうとしない",
                     desc: "気になるところを全部直すと、効果が重なってやりすぎに見える。だから、順番を決める。"),
                    (title: "効きやすい場所から手をつける",
                     desc: "同じ手間でも、眉や目元のほうが頬より圧倒的に印象が変わる。小さいコストで大きなリターンを取る。"),
                    (title: "「見せようとしない」",
                     desc: "ここを見てほしい、と誘導するよりも、さりげなく整えるほうが結果的に効く。")
                ]
            ),

            // Page 28 — principle: Rule 03（追加）
            .principle(
                id: 28, tag: "RULE 03",
                num: "···",
                title: "週3回から始める",
                body: "毎日やろうとすると続かない。\n週3回、「これだけやる」と決めるほうが、1年後に差がつく",
                items: [
                    (title: "月水金でいい",
                     desc: "仕事の日だけやれば十分。休日は素顔でいい。"),
                    (title: "10分以内で完結させる",
                     desc: "道具は3つまで。手順は5ステップ。複雑にすると続かない。"),
                    (title: "化粧品の収納場所を決める",
                     desc: "洗面台の引き出し一段だけ。場所を決めないと面倒になる。")
                ]
            ),

            // Page 29 — principle: Rule 04（追加）
            .principle(
                id: 29, tag: "RULE 04",
                num: "····",
                title: "道具は最小限から",
                body: "最初から全部揃えようとしない。\n一つ試して、慣れてから次を足す",
                items: [
                    (title: "Day 1: BBクリームだけ",
                     desc: "肌のノイズを消すだけで、素の顔より確実に良くなる。"),
                    (title: "Day 8: 眉ペンを足す",
                     desc: "BBクリームに慣れてから。眉だけで印象が変わることに気づく。"),
                    (title: "Day 30: シェーディングを足す",
                     desc: "これで5ステップ中3つが揃う。この段階でも十分すぎる効果がある。")
                ]
            ),

            // Page 30 — goal
            .goal(
                id: 30, tag: "THE TARGET",
                title: "目指すのは、\n「調子のいい日の自分」。",
                quote: "よく寝た翌朝の、\n肌の調子がいい日の、\nあの顔。",
                body: "ここを超えて「他人の顔」を目指すと、\nどこかで違和感が出てくる。\nだから狙うのは、\nあくまで「いつもよりちょっといい自分」。\n\nこれが、いちばん効くし、いちばん続きます。"
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 06: 5ステップ
            // ─────────────────────────────────────────────

            // Page 31 — cover: Chapter 06
            .cover(
                id: 31, tag: "CHAPTER 06",
                chapterNo: "06",
                title: "やることは、\n五つだけ。",
                subtitle: "The five steps",
                body: "ここまでの理屈を、\n顔の上で具体的に何をするか、\nに落とし込んだのが、\n次の五ステップです。\n\n全部「光か影か」の話。"
            ),

            // Page 32 — feature: Step 01 Base
            .feature(
                id: 32, tag: "STEP 01",
                featureNo: "I",
                featureLabel: "Base",
                featureLabelJP: "ベース",
                title: "まず、ノイズを消す。",
                body: "青ヒゲ、赤み、ニキビ跡、シミ。\nこれらはあなたの顔のバランスとは無関係な「雑音」。\n雑音があると、これから作る光と影が、ぼやける。\n\nだから最初にやるのは、足すことじゃなくて、\n「肌のトーンを揃えて、ニュートラルな状態に戻す」こと。"
            ),

            // Page 33 — howto: STEP 01 DETAIL（追加）
            .howto(
                id: 33, tag: "STEP 01 · DETAIL",
                step: "Base",
                title: "BBクリームの選び方",
                body: "基準は「自分の肌色より一段明るいもの」。日本人なら、オークル20〜ベージュ系。ツヤ感があると自然に見える。セミマット仕上がりが崩れにくくてベター。\n\n量は、1円玉大を顔の5点（おでこ・鼻・左右頬・あご）に置いて、外に向かって伸ばすだけ。"
            ),

            // Page 34 — feature: Step 02 Highlight
            .feature(
                id: 34, tag: "STEP 02",
                featureNo: "II",
                featureLabel: "Highlight",
                featureLabelJP: "ハイライト",
                title: "骨を、\n少しだけ立たせる。",
                body: "おでこの中央、鼻筋、頬の高いところ、あご先。\nここに、ほんの少しだけ明るさを入れる。\n\nすると、骨が「ある場所」が前に出てきて、\n顔全体の重心が上がる。\n― 疲れて見えない、若々しい印象の正体は、これ。"
            ),

            // Page 35 — howto: STEP 02 DETAIL（追加）
            .howto(
                id: 35, tag: "STEP 02 · DETAIL",
                step: "Highlight",
                title: "ハイライトの当て方",
                body: "小指の先ほどの量で十分。入れる場所はここだけ：おでこの中央（T字の縦棒）、鼻筋（目頭から鼻先まで）、頬骨の高い部分（目の下、指一本分外側）、あご先の中央。\n\n擦らず、パフでポンポンと乗せるだけ。伸ばそうとしない。"
            ),

            // Page 36 — feature: Step 03 Shadow
            .feature(
                id: 36, tag: "STEP 03",
                featureNo: "III",
                featureLabel: "Shadow",
                featureLabelJP: "シェーディング",
                title: "輪郭を、\nそっと削る。",
                body: "こめかみ、エラ、フェイスラインの下。\nここに薄く影を入れると、\n顔が物理的に小さくなったように見える。\n\n骨格は1ミリも動いてない。\nでも、見え方は確実に変わる。\nこれが、立体感の正体。"
            ),

            // Page 37 — howto: STEP 03 DETAIL（追加）
            .howto(
                id: 37, tag: "STEP 03 · DETAIL",
                step: "Shadow",
                title: "シェーディングの当て方",
                body: "入れる場所：こめかみ（生え際のすぐ内側）、頬の下（頬骨の下から顎に向かって斜めに）、フェイスライン（耳の前から顎先に向かって）。\n\n色は、自分の肌色より2〜3段暗めのブラウン系。グレーは不自然になるので避ける。"
            ),

            // Page 38 — feature: Step 04 Eyes
            .feature(
                id: 38, tag: "STEP 04",
                featureNo: "IV",
                featureLabel: "Eyes",
                featureLabelJP: "アイ",
                title: "目だけは、\nちゃんと作る。",
                body: "会話中、相手はあなたの目をいちばん見ている。\nつまり、ROI（投資対効果）が一番高いのが目元。\n\nまつ毛の生え際を少しだけ濃くして、目力を出す。\n涙袋にほのかな光を入れて、表情を柔らかくする。\nやりすぎなければ、まずバレない。"
            ),

            // Page 39 — howto: STEP 04 DETAIL（追加）
            .howto(
                id: 39, tag: "STEP 04 · DETAIL",
                step: "Eyes",
                title: "目元の仕上げ方",
                body: "まずアイライン。目の際、上まぶたのまつ毛の隙間を埋めるだけ。ラインを引くのではなく、「隙間を塞ぐ」イメージ。ブラックより濃いブラウンのほうがバレにくい。\n\n次に涙袋。目の下の膨らみに、ハイライトを細く入れる。表情が柔らかくなり、目が大きく見える。"
            ),

            // Page 40 — feature: Step 05 Brows
            .feature(
                id: 40, tag: "STEP 05",
                featureNo: "V",
                featureLabel: "Brows",
                featureLabelJP: "眉",
                title: "眉で、\n顔つきが決まる。",
                body: "実は、五つの中でいちばん効くのが眉。\n社会的にも「眉を整える男」は完全に許容されてる。\nつまり、ノーリスクで一番リターンが大きい。\n\n太さ・濃さ・角度を整えるだけで、\n顔の印象が、別人レベルで変わります。"
            ),

            // Page 41 — howto: STEP 05 DETAIL（追加）
            .howto(
                id: 41, tag: "STEP 05 · DETAIL",
                step: "Brows",
                title: "眉の整え方",
                body: "形を変える前に、まず「毛量を揃える」。眉の外側からはみ出している毛だけ、眉バサミで切る。剃らなくていい。\n\n足りない部分をペンで足す。眉頭は薄く、眉尻は濃く。全体に均一に描くと不自然になる。最後に眉マスカラで色と方向を揃える。"
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 07: よくある失敗（新規）
            // ─────────────────────────────────────────────

            // Page 42 — cover: Chapter 07（追加）
            .cover(
                id: 42, tag: "CHAPTER 07",
                chapterNo: "07",
                title: "よくある、\nちょうどいい失敗。",
                subtitle: "Common mistakes",
                body: "初めてやると、必ずどれかひとつは経験する。\n経験してから気づく人が多いので、\n先に言っておきます。"
            ),

            // Page 43 — principle: MISTAKE 01（追加）
            .principle(
                id: 43, tag: "MISTAKE 01",
                num: "!",
                title: "「全部やる」で逆効果",
                body: "最初から5ステップ全部やると、補正が重なって「やり過ぎ感」が出る。最初は1〜2ステップだけ。それで十分効く",
                items: [
                    (title: "やりがちな失敗",
                     desc: "気合が入って全部塗ってみる → 友人に「なんか顔色変じゃない？」と言われる → 心が折れてやめる。"),
                    (title: "正しいアプローチ",
                     desc: "最初はBBクリームだけ。1週間後、慣れたら眉を足す。これだけで十分変わる。")
                ]
            ),

            // Page 44 — principle: MISTAKE 02（追加）
            .principle(
                id: 44, tag: "MISTAKE 02",
                num: "!!",
                title: "量が多すぎる",
                body: "少ないと思っても、鏡の前では分からない。外に出て自然光で見ると初めて分かる。最初は「え、これで効果あるの？」というくらいで丁度いい",
                items: [
                    (title: "量の目安",
                     desc: "ファンデは1円玉大。ハイライトは小指の先1mm。シェーディングは眉サイズ。このくらいで十分。"),
                    (title: "量が多い時のサイン",
                     desc: "鏡で見て「なんか白い」「パールが光りすぎ」と感じたら、確実に多い。ティッシュで軽くオフする。")
                ]
            ),

            // Page 45 — principle: MISTAKE 03（追加）
            .principle(
                id: 45, tag: "MISTAKE 03",
                num: "!!!",
                title: "「バレたくない」が強すぎて効果ゼロ",
                body: "気づかれないために薄くしすぎると、意味がない量になる。「鏡でパッと見て変化を感じる量」が正解。他人は思ってるより気にしていない",
                items: [
                    (title: "適量の感覚",
                     desc: "鏡から60cm離れて見て、前より良いと思えるか。これがコントロールポイント。"),
                    (title: "周りの反応",
                     desc: "「今日なんかいい感じ」「肌きれい」「なんか違う」―この反応が出たら成功。「化粧してる」とは言われない。")
                ]
            ),

            // ─────────────────────────────────────────────
            // CHAPTER 08: 最後の一歩（新規）
            // ─────────────────────────────────────────────

            // Page 46 — cover: Chapter 08（追加）
            .cover(
                id: 46, tag: "CHAPTER 08",
                chapterNo: "08",
                title: "始めるのに、\n完璧な準備はいらない。",
                subtitle: "Start now",
                body: "道具が揃ってから、じゃなくていい。\n技術が上手くなってから、じゃなくていい。\n\n今日、一つだけ試せばいい。"
            ),

            // Page 47 — stat: 21日（追加）
            .stat(
                id: 47, tag: "FINAL FACT",
                stat: "21日",
                statLabel: "新習慣が定着するまでの日数",
                body: "21日間、同じことを続けると\n脳の回路が変わる。\n「やらないと落ち着かない」に変わる。\n\n今日が、その21日目のカウントダウンの、\n1日目。",
                source: "出典: Maxwell Maltz (1960)"
            ),

            // ─────────────────────────────────────────────
            // 締め
            // ─────────────────────────────────────────────

            // Page 48 — list
            .list(
                id: 48, tag: "WHAT WE PROMISE",
                title: "このアプリは、\n三つを守ります。",
                listItems: [
                    (title: "「気づかれない範囲」をデフォルトに",
                     desc: "初期値はすべて「自然にあり得る範囲」に押さえています。もっと強く出したい人はスライダーを上げてください。"),
                    (title: "理屈の通った提案だけをする",
                     desc: "プリセットも、シェーディングの位置も、すべて顔の比率と光と影の理論で決めています。「なんとなく良さげ」では出しません。"),
                    (title: "画像は、端末から出さない",
                     desc: "顔写真はサーバーに送信されません。AIの解析もすべて、あなたのスマホの中で完結します。")
                ]
            ),

            // Page 49 — howto: 1/3
            .howto(
                id: 49, tag: "HOW IT WORKS · 1/3",
                step: "01",
                title: "撮る、または送る",
                body: "正面の顔写真を一枚だけ。\n明るい場所・無表情・前髪なしが理想。\n\n顔の比率と骨格を、客観的な数値で読み取ります。"
            ),

            // Page 50 — howto: 2/3
            .howto(
                id: 50, tag: "HOW IT WORKS · 2/3",
                step: "02",
                title: "診断を読む",
                body: "あなたの顔のバランスを\n七つの観点でスコア化。\n\n「あなたの顔は、ここを補正するとリターンが大きい」を\n具体的に教えてくれます。"
            ),

            // Page 51 — howto: 3/3
            .howto(
                id: 51, tag: "HOW IT WORKS · 3/3",
                step: "03",
                title: "顔の上で、試す",
                body: "五ステップを順番に、自分の顔に重ねて確認。\n強さはスライダーで0からMAXまで自由に。\n\nビフォー/アフターを比較して、気に入ったら保存。"
            ),

            // Page 52 — cta
            .cta(
                id: 52, tag: "LET'S BEGIN",
                title: "読むのは、\nここまで。",
                body: "ここから先は、\nあなたの顔の上で試したほうが早い。\n\n― 30秒で、最初の変化が見られます。"
            )
        ]
    }
}
