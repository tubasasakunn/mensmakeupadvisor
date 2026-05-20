import Foundation

// 章ジャンプ用の Index。Onboarding 53 ページの中の章境界 (cover ページ)
// を 8 つに集約し、目次シートと Home からの再アクセスで参照する。
struct OnboardingChapter: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let firstPageIndex: Int

    static let all: [OnboardingChapter] = [
        .init(id: "01", title: "共感",
              subtitle: "鏡を見るたび、何かが惜しい",
              firstPageIndex: 0),
        .init(id: "02", title: "なぜやるか",
              subtitle: "「身嗜み」で、「化粧」じゃない",
              firstPageIndex: 7),
        .init(id: "03", title: "理論",
              subtitle: "メイクには、ちゃんと理屈がある",
              firstPageIndex: 13),
        .init(id: "04", title: "光と影",
              subtitle: "結局、光と影",
              firstPageIndex: 20),
        .init(id: "05", title: "男性特有",
              subtitle: "「気づかれない」が前提",
              firstPageIndex: 25),
        .init(id: "06", title: "5 ステップ",
              subtitle: "やることは、五つだけ",
              firstPageIndex: 31),
        .init(id: "07", title: "よくある失敗",
              subtitle: "ちょうどいい失敗",
              firstPageIndex: 42),
        .init(id: "08", title: "最後の一歩",
              subtitle: "ここから先は、読む話じゃない",
              firstPageIndex: 46),
    ]

    // 現在のページ番号 (0-based) を含む章を返す。
    static func current(forPage page: Int) -> OnboardingChapter {
        let last = all.last!
        for i in stride(from: all.count - 1, through: 0, by: -1)
            where all[i].firstPageIndex <= page {
            return all[i]
        }
        return last
    }
}
