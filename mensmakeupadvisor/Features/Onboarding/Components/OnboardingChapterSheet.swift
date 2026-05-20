import SwiftUI

// 章ジャンプの目次シート。OnboardingView から呼ばれて、現在ページ index
// を Binding で書き換える。tap で即遷移 + シートクローズ。
struct OnboardingChapterSheet: View {
    @Binding var currentPage: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    chapterList
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Color.appBackground)
        .presentationDragIndicator(.visible)
        .aid("onboarding_chapter_sheet")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("目次")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.ivory)
            Text("読みたい章をタップしてください")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.bottom, 16)
    }

    private var chapterList: some View {
        let currentChapter = OnboardingChapter.current(forPage: currentPage)
        return VStack(spacing: 0) {
            ForEach(OnboardingChapter.all) { ch in
                let isCurrent = ch.id == currentChapter.id
                Button {
                    currentPage = ch.firstPageIndex
                    dismiss()
                } label: {
                    chapterRow(chapter: ch, isCurrent: isCurrent)
                }
                .accessibilityLabel(
                    "第 \(ch.id) 章 \(ch.title)" + (isCurrent ? "。現在の章" : "")
                )
                .aid("onboarding_chapter_\(ch.id)")

                Rectangle().fill(Color.lineColor).frame(height: 1)
            }
        }
    }

    private func chapterRow(chapter ch: OnboardingChapter, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            Text(ch.id)
                .font(.system(size: 18, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(isCurrent ? Color.brandPrimary : Color.inkSecondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(ch.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ivory)
                Text(ch.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isCurrent {
                Image(systemName: "location.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkTertiary)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    @Previewable @State var page = 14
    return OnboardingChapterSheet(currentPage: $page)
}
