import UIKit
import SwiftUI

// 全ページタイプを kind に応じてスイッチするディスパッチャー
struct OnboardPageContentView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    switch page.kind {
                    case .cover:     CoverPageView(page: page)
                    case .stat:      StatPageView(page: page)
                    case .compare:   ComparePageView(page: page)
                    case .concept:   ConceptPageView(page: page)
                    case .thesis:    ThesisPageView(page: page)
                    case .principle: PrinciplePageView(page: page)
                    case .duo:       DuoPageView(page: page)
                    case .example:   ExamplePageView(page: page)
                    case .goal:      GoalPageView(page: page)
                    case .list:      ListPageView(page: page)
                    case .feature:   FeaturePageView(page: page)
                    case .howto:     HowtoPageView(page: page)
                    case .cta:       CtaPageView(page: page)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: geo.size.height, alignment: .top)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Cover

private struct CoverPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 章番号（赤・イタリック・大きい）
            if let no = page.chapterNo {
                Text(no)
                    .font(.system(size: 88, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.bottom, 4)
            }

            // タイトル（日本語・大きい）
            if let title = page.title {
                Text(title)
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 16)
            }

            // サブタイトル（英語・モノスペース）
            if let sub = page.subtitle {
                Text(sub)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
                    .padding(.bottom, 24)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 24)

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

// MARK: - Stat

private struct StatPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 32)

            // stat ラベル（KBD スタイル）
            if let tag = Optional(page.tag) {
                Text(tag)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(2.5)
                    .padding(.bottom, 31)
            }

            // 超大きな統計値
            if let stat = page.stat {
                Text(stat)
                    .font(.system(size: 88, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.bottom, 10)
            }

            // 統計ラベル
            if let label = page.statLabel {
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ivory.opacity(0.85))
                    .lineSpacing(5)
                    .padding(.bottom, 26)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 21)

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, 16)
            }

            // 出典
            if let source = page.source {
                Text(source)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary.opacity(0.6))
                    .kerning(0.5)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

// MARK: - Compare (Before / After slider)

private struct ComparePageView: View {
    let page: OnboardingPage
    @State private var sliderX: CGFloat = 0.5   // 0.0 = full before, 1.0 = full after

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
            }

            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .padding(.bottom, 20)
            }

            // Before/After 比較スライダー
            BeforeAfterSlider(sliderX: $sliderX)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier("onboarding_compare_slider")
        }
        .padding(.top, 16)
    }
}

// ドラッグ可能な Before/After 比較スライダー
private struct BeforeAfterSlider: View {
    @Binding var sliderX: CGFloat   // 0〜1
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let splitX = w * sliderX

            ZStack(alignment: .leading) {
                // Before 側（左）— やや暗く・彩度低め
                ZStack {
                    if let img = UIImage(named: "sample_face") {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w, height: h)
                            .saturation(0.25)
                            .brightness(-0.08)
                            .clipped()
                    } else {
                        Rectangle().fill(Color(white: 0.18))
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Text("BEFORE")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.inkSecondary)
                                .kerning(2)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                            Spacer()
                        }
                    }
                    .padding(8)
                }

                // After 側（右）— 整った肌表現
                ZStack {
                    if let img = UIImage(named: "sample_face") {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w, height: h)
                            .brightness(0.05)
                            .clipped()
                    } else {
                        Rectangle().fill(Color(white: 0.26))
                    }
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("AFTER")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(Color.ivory.opacity(0.8))
                                .kerning(2)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                        }
                    }
                    .padding(8)
                }
                .frame(width: w - splitX)
                .offset(x: splitX)

                // ダイヤモンドアイコン付きドラッグバー
                ZStack {
                    Rectangle()
                        .fill(Color.ivory.opacity(0.9))
                        .frame(width: 2)

                    Circle()
                        .fill(Color.ivory)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "arrow.left.arrow.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.appBackground)
                        )
                }
                .frame(height: h)
                .offset(x: splitX - 14)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let rawX = value.location.x / w
                        let newX = max(0, min(1, rawX))
                        sliderX = newX
                    }
            )
        }
    }
}

// MARK: - Concept

private struct ConceptPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 英語イタリックタイトル（大きい）
            if let ct = page.conceptTitle {
                Text(ct)
                    .font(.system(size: 60, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 4)
            }

            // 日本語サブタイトル
            if let jp = page.titleJP {
                Text(jp)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
                    .kerning(2)
                    .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, 12)
            }

            // 出典
            if let source = page.source {
                Text(source)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary.opacity(0.6))
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

// MARK: - Thesis

private struct ThesisPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The Thesis.")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
                .padding(.bottom, 20)

            // タイトル
            if let title = page.title {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 16)
            }

            // 複合テキスト — 赤いキーワード混じり
            // body1 + highlight(赤) + body2 + body3(赤) + body4 + body5
            compositeText
                .font(.system(size: 22, weight: .regular, design: .serif))
                .lineSpacing(12)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }

    private var compositeText: some View {
        Group {
            buildText()
        }
    }

    private func buildText() -> Text {
        var result = Text("")
        if let b1 = page.body1 {
            result = result + Text(b1).foregroundColor(Color.ivory)
        }
        if let hl = page.highlight {
            result = result + Text(hl)
                .foregroundColor(Color.brandPrimary)
                .bold()
        }
        if let b2 = page.body2 {
            result = result + Text(b2).foregroundColor(Color.ivory)
        }
        if let b3 = page.body3 {
            result = result + Text("\n") + Text(b3)
                .foregroundColor(Color.brandPrimary)
                .bold()
        }
        if let b4 = page.body4 {
            result = result + Text(b4).foregroundColor(Color.ivory)
        }
        if let b5 = page.body5 {
            result = result + Text("\n") + Text(b5).foregroundColor(Color.ivory)
        }
        return result
    }
}

// MARK: - Principle

private struct PrinciplePageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 大きな番号
            if let num = page.num {
                Text(num)
                    .font(.system(size: 80, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary.opacity(0.7))
                    .padding(.bottom, -8)
            }

            // タイトル
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
            }

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .padding(.bottom, 20)
            }

            // アイテムリスト
            if let items = page.items {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items.indices, id: \.self) { i in
                        PrincipleItemRow(title: items[i].title, desc: items[i].desc)
                    }
                }
                .padding(.bottom, 12)
            }

            // フッター
            if let footer = page.footer {
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(height: 1)
                    .padding(.bottom, 10)

                Text(footer)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkSecondary.opacity(0.7))
                    .lineSpacing(4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

private struct PrincipleItemRow: View {
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.ivory)

            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(4)
        }
        .padding(.leading, 12)
        .overlay(
            Rectangle()
                .fill(Color.brandPrimary.opacity(0.6))
                .frame(width: 2),
            alignment: .leading
        )
    }
}

// MARK: - Duo

private struct DuoPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 20)

            HStack(alignment: .top, spacing: 16) {
                // Left: Light
                DuoColumn(
                    label: page.leftLabel ?? "",
                    labelJP: page.leftJP ?? "",
                    desc: page.leftDesc ?? "",
                    accentColor: Color.ivory
                )

                // 縦区切り線
                Rectangle()
                    .fill(Color.lineColor)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)

                // Right: Shadow
                DuoColumn(
                    label: page.rightLabel ?? "",
                    labelJP: page.rightJP ?? "",
                    desc: page.rightDesc ?? "",
                    accentColor: Color.inkSecondary
                )
            }
        }
        .padding(.top, 16)
    }
}

private struct DuoColumn: View {
    let label: String
    let labelJP: String
    let desc: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(accentColor)

            Text(labelJP)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(accentColor.opacity(0.7))
                .kerning(0.5)
                .lineSpacing(3)

            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 1)

            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Example

private struct ExamplePageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 20)
            }

            if let items = page.exampleItems {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(items.indices, id: \.self) { i in
                        ExampleItemView(
                            index: i + 1,
                            concern: items[i].concern,
                            advice: items[i].advice
                        )
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

private struct ExampleItemView: View {
    let index: Int
    let concern: String
    let advice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // お悩み
            HStack(alignment: .top, spacing: 8) {
                Text("Q")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 2)
                Text(concern)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(3)
            }

            // アドバイス
            HStack(alignment: .top, spacing: 8) {
                Text("→")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 2)
                Text(advice)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(14)
        .background(Color.ivory.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.lineColor, lineWidth: 1)
        )
    }
}

// MARK: - Goal

private struct GoalPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            // プルクォート（左に赤い縦線）
            if let quote = page.quote {
                HStack(alignment: .top, spacing: 14) {
                    Rectangle()
                        .fill(Color.brandPrimary)
                        .frame(width: 3)

                    Text(quote)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)
                        .lineSpacing(6)
                }
                .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

// MARK: - List

private struct ListPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            if let items = page.listItems {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items.indices, id: \.self) { i in
                        NumberedListItem(
                            number: String(format: "%02d", i + 1),
                            title: items[i].title,
                            desc: items[i].desc
                        )
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

private struct NumberedListItem: View {
    let number: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.brandPrimary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ivory)

                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Feature (tutorial step preview)

private struct FeaturePageView: View {
    let page: OnboardingPage

    private var regionKey: String {
        switch page.featureLabel {
        case "Base":      "base"
        case "Highlight": "highlight"
        case "Shadow":    "shadow"
        case "Eyes":      "eyes"
        case "Brows":     "brows"
        default:          "base"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // ステップ番号（ローマ数字・大きい）
                    if let no = page.featureNo {
                        Text(no)
                            .font(.system(size: 52, weight: .bold, design: .serif))
                            .italic()
                            .foregroundStyle(Color.brandPrimary)
                    }

                    // ラベル（英語）
                    if let label = page.featureLabel {
                        Text(label)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Color.ivory)
                    }

                    // ラベル（日本語）
                    if let jp = page.featureLabelJP {
                        Text(jp)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color.inkSecondary)
                            .kerning(1.5)
                    }
                }

                Spacer()

                // 顔の線画
                FaceDiagramView(
                    region: regionKey,
                    caption: "FIG. \(page.featureLabel?.uppercased() ?? "")"
                )
            }
            .padding(.bottom, 16)

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 14)

            // タイトル
            if let title = page.title {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 10)
            }

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(6)
            }
        }
        .padding(.top, 16)
    }
}

// MARK: - Howto

private struct HowtoPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 大きなステップ番号
            if let step = page.step {
                Text(step)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary.opacity(0.28))
                    .padding(.bottom, -30)
            }

            // タイトル
            if let title = page.title {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 14)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 14)

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 8)
    }
}

// MARK: - CTA

private struct CtaPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // エピグラフ
            Text("And so, we begin.")
                .font(.system(size: 13, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.inkSecondary)
                .kerning(0.5)
                .padding(.bottom, 24)

            // タイトル
            if let title = page.title {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            // 本文
            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 24)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardPageContentView(page: OnboardingPage.all[0])
    }
}
