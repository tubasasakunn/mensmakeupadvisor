import SwiftUI

// 章ジャンプの目次シート。OnboardingView から呼ばれて、現在ページ index
// を Binding で書き換える。tap で即遷移 + シートクローズ。
struct OnboardingChapterSheet: View {
    @Binding var currentPage: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    chapterList
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.xl)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.thinMaterial)
        .presentationDragIndicator(.visible)
        .aid("onboarding_chapter_sheet")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("目次")
                .font(Theme.Typography.UI.title2Bold)
                .foregroundStyle(Color.ivory)
            Text("読みたい章をタップしてください")
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    private var chapterList: some View {
        let currentChapter = OnboardingChapter.current(forPage: currentPage)
        return VStack(spacing: 0) {
            ForEach(OnboardingChapter.all) { ch in
                let isCurrent = ch.id == currentChapter.id
                Button {
                    Haptics.selection()
                    currentPage = ch.firstPageIndex
                    dismiss()
                } label: {
                    chapterRow(chapter: ch, isCurrent: isCurrent)
                }
                .accessibilityLabel(
                    "第 \(ch.id) 章 \(ch.title)" + (isCurrent ? "。現在の章" : "")
                )
                .aid("onboarding_chapter_\(ch.id)")

                HairlineDivider()
            }
        }
    }

    private func chapterRow(chapter ch: OnboardingChapter, isCurrent: Bool) -> some View {
        HStack(spacing: 14) {
            Text(ch.id)
                .font(Theme.Typography.Display.title3Light)
                .italic()
                .foregroundStyle(isCurrent ? Color.brandPrimary : Color.inkSecondary)
                .frame(width: Theme.Size.Column.chapter, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(ch.title)
                    .font(Theme.Typography.UI.bodyLargeSemibold)
                    .foregroundStyle(Color.ivory)
                Text(ch.subtitle)
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Color.inkSecondary)
                    .lineLimit(2)
            }

            Spacer()

            if isCurrent {
                Image(systemName: "location.fill")
                    .font(Theme.Typography.UI.footnoteSemibold)
                    .foregroundStyle(Color.brandPrimary)
            } else {
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.UI.subheadlineSemibold)
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
