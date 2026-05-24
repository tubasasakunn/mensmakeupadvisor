import SwiftUI

// Studio「次へ」のあとに挟む、保存名前付け用の軽量シート。
// デフォルト名 (例: "5月24日のメイク") を埋めた状態で出すので、
// ユーザーは触らずに右上「保存」を押すだけで通過できる体験。
// メモは任意。
struct SaveTitleSheet: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void

    @State private var title: String = StudioViewModel.defaultTitle()
    @State private var memo: String = ""
    @FocusState private var focused: Field?

    private enum Field { case title, memo }

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)

            VStack(spacing: 0) {
                header
                    .padding(.top, Theme.Spacing.sm)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxl) {
                        titleBlock
                        titleField
                        memoField
                        hint
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
        .aid("save_title_sheet")
    }

    // MARK: - Header

    private var header: some View {
        ScreenHeader(
            variant: .sheet,
            kicker: "SAVE",
            backAccessibilityLabel: "保存をキャンセルしてスタジオに戻る",
            backAccessibilityID: "save_title_cancel",
            onBack: {
                focused = nil
                onCancel()
            },
            trailing: { saveButton }
        )
    }

    private var saveButton: some View {
        Button {
            Haptics.success()
            focused = nil
            onSave(title, memo)
        } label: {
            Text("保存")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.ivory)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 7)
                .glassEffect(.regular, in: .capsule)
        }
        .accessibilityLabel("この仕上がりを保存する")
        .aid("save_title_save")
    }

    // MARK: - Body

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("送り出す前に。")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
            Text("名前をつけて、自分の記録に残す。")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
        }
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            fieldLabel("TITLE")
            TextField(
                "",
                text: $title,
                prompt: Text("名前を入力")
                    .foregroundStyle(Theme.Text.tertiary)
            )
            .font(.system(size: 20, weight: .medium, design: .serif))
            .italic()
            .foregroundStyle(Color.ivory)
            .focused($focused, equals: .title)
            .submitLabel(.next)
            .onSubmit { focused = .memo }
            .padding(.vertical, Theme.Spacing.sm)
            .aid("save_title_field")
            HairlineDivider()
        }
    }

    private var memoField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            fieldLabel("MEMO  ·  OPTIONAL")
            TextField(
                "",
                text: $memo,
                prompt: Text("一言メモ（任意）")
                    .foregroundStyle(Theme.Text.tertiary),
                axis: .vertical
            )
            .font(.system(size: 14))
            .foregroundStyle(Color.ivory)
            .lineLimit(2...5)
            .focused($focused, equals: .memo)
            .padding(.vertical, Theme.Spacing.sm)
            .aid("save_memo_field")
            HairlineDivider()
        }
    }

    private var hint: some View {
        HStack(spacing: 6) {
            Image(systemName: "archivebox")
                .font(.system(size: 10))
            Text("保存した記録はアーカイブから何度でも開けます。")
                .font(.system(size: 11))
        }
        .foregroundStyle(Theme.Text.tertiary)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .kerning(2)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }
}

#Preview {
    SaveTitleSheet(onSave: { _, _ in }, onCancel: {})
}
