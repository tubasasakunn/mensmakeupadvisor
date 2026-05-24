import SwiftUI

// 画面上部のナビゲーションバー共通コンポーネント。
//
// 既存の各画面で left chevron + label の独自実装が散らばっており、
// 戻るラベルが「戻る / 前へ / ホーム / 診断結果」と暴れていたため
// ここで一本化する。文脈は accessibilityLabel に逃がし、視覚的には
// 全画面「戻る」一語に統一する。
//
// バリアント:
//   .push  — chevron.left + "戻る"   （Capture / Diagnosis / Tutorial / Studio）
//   .sheet — xmark のみ              （SavedLookDetailSheet / 各種モーダル）
//
// 中央 kicker は等幅大文字（"STUDIO" "RESULT" "GUIDE 1/5" 等）。
// trailing は画面固有の primary action（共有 / 編集 等）。
struct ScreenHeader<Trailing: View>: View {
    enum Variant {
        case push
        case sheet
    }

    let variant: Variant
    let kicker: String?
    let backAccessibilityLabel: String
    let backAccessibilityID: String
    let onBack: () -> Void
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            backButton
            Spacer(minLength: 0)
            if let kicker {
                kickerLabel(kicker)
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, Theme.Spacing.xxl)
        .frame(height: 44)
    }

    @ViewBuilder
    private var backButton: some View {
        switch variant {
        case .push:  pushBackButton
        case .sheet: sheetCloseButton
        }
    }

    private var pushBackButton: some View {
        Button {
            Haptics.soft()
            onBack()
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
                Text("戻る")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 7)
            .glassEffect(.clear, in: .capsule)
        }
        .accessibilityLabel(backAccessibilityLabel)
        .aid(backAccessibilityID)
    }

    private var sheetCloseButton: some View {
        Button {
            Haptics.soft()
            onBack()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Text.primarySoft)
                .frame(width: 30, height: 30)
                .glassEffect(.clear, in: .circle)
        }
        .accessibilityLabel(backAccessibilityLabel)
        .aid(backAccessibilityID)
    }

    private func kickerLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .kerning(2.5)
            .foregroundStyle(Theme.Text.primaryFaded)
            .accessibilityHidden(true)
    }
}

// trailing 無し版の便利 init。
extension ScreenHeader where Trailing == EmptyView {
    init(
        variant: Variant,
        kicker: String? = nil,
        backAccessibilityLabel: String,
        backAccessibilityID: String,
        onBack: @escaping () -> Void
    ) {
        self.variant = variant
        self.kicker = kicker
        self.backAccessibilityLabel = backAccessibilityLabel
        self.backAccessibilityID = backAccessibilityID
        self.onBack = onBack
        self.trailing = { EmptyView() }
    }
}

// MARK: - Preview

#Preview("push - kicker only") {
    ZStack {
        LuxeBackground()
        VStack {
            ScreenHeader(
                variant: .push,
                kicker: "RESULT",
                backAccessibilityLabel: "撮影画面に戻る",
                backAccessibilityID: "preview_back",
                onBack: {}
            )
            Spacer()
        }
    }
}

#Preview("push - kicker + share trailing") {
    ZStack {
        LuxeBackground()
        VStack {
            ScreenHeader(
                variant: .push,
                kicker: "STUDIO",
                backAccessibilityLabel: "診断結果に戻る",
                backAccessibilityID: "preview_back",
                onBack: {},
                trailing: {
                    Button {} label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.Text.primarySoft)
                            .frame(width: 30, height: 30)
                            .glassEffect(.clear, in: .circle)
                    }
                }
            )
            Spacer()
        }
    }
}

#Preview("sheet variant") {
    ZStack {
        LuxeBackground()
        VStack {
            ScreenHeader(
                variant: .sheet,
                kicker: "ARCHIVE",
                backAccessibilityLabel: "閉じる",
                backAccessibilityID: "preview_close",
                onBack: {},
                trailing: {
                    Button("編集") {}
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Text.primarySoft)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, 7)
                        .glassEffect(.clear, in: .capsule)
                }
            )
            Spacer()
        }
    }
}
