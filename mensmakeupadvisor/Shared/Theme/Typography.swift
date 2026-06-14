import SwiftUI

// アプリ全体のタイポグラフィ・トークン (フォント)。
//
// **このファイルがフォント指定の唯一の真実**。View で `.font(.system(size:...))` を
// 新たに書かないこと。新しい字面が欲しいときは、まずここにトークンを追加してから参照する。
//
// 設計方針:
// - 3 つの字面ファミリで分類する。
//     UI      … 既定 design。画面 UI の本文・ラベル・見出し。
//     Data    … monospaced。スコア・数値・技術ラベル (桁が揃う)。
//     Display … serif。エディトリアルな見出しと大きな数字 (アプリの世界観)。
// - 名前は「サイズ階調 + ウェイト接尾辞」。ウェイト無指定はシステム既定。
// - **値は現行のデザインをそのまま保持**している (px は意図的に Apple 既定と一致しない)。
//   調整したくなったらここを 1 箇所直す。視覚を変える変更はデザインレビューを通す。
// - `italic` は字面ではなくスタイルなので、従来どおり `.italic()` を併用する。
// - Swift 6 strict concurrency に合わせ `nonisolated static let` で公開する。

extension Theme {
    enum Typography {

        // MARK: - UI (既定 design — 本文・ラベル・見出し)
        enum UI {
            nonisolated static let caption2Medium: Font = .system(size: 9, weight: .medium)
            nonisolated static let caption: Font = .system(size: 10)
            nonisolated static let captionRegular: Font = .system(size: 10, weight: .regular)
            nonisolated static let captionMedium: Font = .system(size: 10, weight: .medium)
            nonisolated static let captionSemibold: Font = .system(size: 10, weight: .semibold)
            nonisolated static let footnote: Font = .system(size: 11)
            nonisolated static let footnoteRegular: Font = .system(size: 11, weight: .regular)
            nonisolated static let footnoteMedium: Font = .system(size: 11, weight: .medium)
            nonisolated static let footnoteSemibold: Font = .system(size: 11, weight: .semibold)
            nonisolated static let footnoteBold: Font = .system(size: 11, weight: .bold)
            nonisolated static let subheadline: Font = .system(size: 12)
            nonisolated static let subheadlineRegular: Font = .system(size: 12, weight: .regular)
            nonisolated static let subheadlineMedium: Font = .system(size: 12, weight: .medium)
            nonisolated static let subheadlineSemibold: Font = .system(size: 12, weight: .semibold)
            nonisolated static let callout: Font = .system(size: 13)
            nonisolated static let calloutRegular: Font = .system(size: 13, weight: .regular)
            nonisolated static let calloutMedium: Font = .system(size: 13, weight: .medium)
            nonisolated static let calloutSemibold: Font = .system(size: 13, weight: .semibold)
            nonisolated static let calloutHeavy: Font = .system(size: 13, weight: .heavy)
            nonisolated static let body: Font = .system(size: 14)
            nonisolated static let bodyRegular: Font = .system(size: 14, weight: .regular)
            nonisolated static let bodyMedium: Font = .system(size: 14, weight: .medium)
            nonisolated static let bodySemibold: Font = .system(size: 14, weight: .semibold)
            nonisolated static let bodyHeavy: Font = .system(size: 14, weight: .heavy)
            nonisolated static let bodyLargeRegular: Font = .system(size: 15, weight: .regular)
            nonisolated static let bodyLargeMedium: Font = .system(size: 15, weight: .medium)
            nonisolated static let bodyLargeSemibold: Font = .system(size: 15, weight: .semibold)
            nonisolated static let headlineMedium: Font = .system(size: 16, weight: .medium)
            nonisolated static let headlineBold: Font = .system(size: 16, weight: .bold)
            nonisolated static let title3Semibold: Font = .system(size: 18, weight: .semibold)
            nonisolated static let title3Heavy: Font = .system(size: 18, weight: .heavy)
            nonisolated static let title2Semibold: Font = .system(size: 22, weight: .semibold)
            nonisolated static let title2Bold: Font = .system(size: 22, weight: .bold)
            nonisolated static let titleBold: Font = .system(size: 24, weight: .bold)
            nonisolated static let titleLarge: Font = .system(size: 26)
            nonisolated static let display: Font = .system(size: 28)
            nonisolated static let displayLargeSemibold: Font = .system(size: 32, weight: .semibold)
            // 空状態などの大きな SF Symbol グリフ
            nonisolated static let numeralUltraLight: Font = .system(size: 40, weight: .ultraLight)
            nonisolated static let s15Heavy: Font = .system(size: 15, weight: .heavy)
            nonisolated static let s36UltraLight: Font = .system(size: 36, weight: .ultraLight)
        }

        // MARK: - Data (monospaced — スコア・数値・技術ラベル)
        enum Data {
            nonisolated static let nanoMedium: Font = .system(size: 5, weight: .medium, design: .monospaced)
            nonisolated static let microRegular: Font = .system(size: 7, weight: .regular, design: .monospaced)
            nonisolated static let tiny: Font = .system(size: 8, design: .monospaced)
            nonisolated static let tinyRegular: Font = .system(size: 8, weight: .regular, design: .monospaced)
            nonisolated static let tinyMedium: Font = .system(size: 8, weight: .medium, design: .monospaced)
            nonisolated static let tinySemibold: Font = .system(size: 8, weight: .semibold, design: .monospaced)
            nonisolated static let miniRegular: Font = .system(size: 9, weight: .regular, design: .monospaced)
            nonisolated static let miniMedium: Font = .system(size: 9, weight: .medium, design: .monospaced)
            nonisolated static let miniSemibold: Font = .system(size: 9, weight: .semibold, design: .monospaced)
            nonisolated static let small: Font = .system(size: 10, design: .monospaced)
            nonisolated static let smallRegular: Font = .system(size: 10, weight: .regular, design: .monospaced)
            nonisolated static let smallMedium: Font = .system(size: 10, weight: .medium, design: .monospaced)
            nonisolated static let smallSemibold: Font = .system(size: 10, weight: .semibold, design: .monospaced)
            nonisolated static let base: Font = .system(size: 11, design: .monospaced)
            nonisolated static let baseLight: Font = .system(size: 11, weight: .light, design: .monospaced)
            nonisolated static let baseRegular: Font = .system(size: 11, weight: .regular, design: .monospaced)
            nonisolated static let baseMedium: Font = .system(size: 11, weight: .medium, design: .monospaced)
            nonisolated static let baseBlack: Font = .system(size: 11, weight: .black, design: .monospaced)
            nonisolated static let mediumMedium: Font = .system(size: 12, weight: .medium, design: .monospaced)
            nonisolated static let largeLight: Font = .system(size: 14, weight: .light, design: .monospaced)
            nonisolated static let largeMedium: Font = .system(size: 14, weight: .medium, design: .monospaced)
            nonisolated static let heroBlack: Font = .system(size: 20, weight: .black, design: .monospaced)
            nonisolated static let s12: Font = .system(size: 12, design: .monospaced)
        }

        // MARK: - Display (serif — エディトリアル見出し・大きな数字)
        enum Display {
            nonisolated static let miniBold: Font = .system(size: 7, weight: .bold, design: .serif)
            nonisolated static let captionLight: Font = .system(size: 12, weight: .light, design: .serif)
            nonisolated static let footnoteLight: Font = .system(size: 13, weight: .light, design: .serif)
            nonisolated static let footnoteSemibold: Font = .system(size: 13, weight: .semibold, design: .serif)
            nonisolated static let labelBlack: Font = .system(size: 14, weight: .black, design: .serif)
            nonisolated static let calloutLight: Font = .system(size: 15, weight: .light, design: .serif)
            nonisolated static let calloutMedium: Font = .system(size: 15, weight: .medium, design: .serif)
            nonisolated static let calloutSemibold: Font = .system(size: 15, weight: .semibold, design: .serif)
            nonisolated static let subheadLight: Font = .system(size: 16, weight: .light, design: .serif)
            nonisolated static let headlineSemibold: Font = .system(size: 17, weight: .semibold, design: .serif)
            nonisolated static let title3Light: Font = .system(size: 18, weight: .light, design: .serif)
            nonisolated static let title2Light: Font = .system(size: 20, weight: .light, design: .serif)
            nonisolated static let title2Medium: Font = .system(size: 20, weight: .medium, design: .serif)
            nonisolated static let title2Bold: Font = .system(size: 20, weight: .bold, design: .serif)
            nonisolated static let titleLight: Font = .system(size: 22, weight: .light, design: .serif)
            nonisolated static let titleRegular: Font = .system(size: 22, weight: .regular, design: .serif)
            nonisolated static let titleSemibold: Font = .system(size: 22, weight: .semibold, design: .serif)
            nonisolated static let titleBold: Font = .system(size: 22, weight: .bold, design: .serif)
            nonisolated static let titleLBold: Font = .system(size: 24, weight: .bold, design: .serif)
            nonisolated static let displayBold: Font = .system(size: 26, weight: .bold, design: .serif)
            nonisolated static let displayLBold: Font = .system(size: 28, weight: .bold, design: .serif)
            nonisolated static let heroBold: Font = .system(size: 30, weight: .bold, design: .serif)
            nonisolated static let heroLLight: Font = .system(size: 32, weight: .light, design: .serif)
            nonisolated static let heroLBold: Font = .system(size: 32, weight: .bold, design: .serif)
            nonisolated static let heroXLBold: Font = .system(size: 36, weight: .bold, design: .serif)
            nonisolated static let numeralLight: Font = .system(size: 40, weight: .light, design: .serif)
            nonisolated static let numeralLLight: Font = .system(size: 42, weight: .light, design: .serif)
            nonisolated static let numeralXLLight: Font = .system(size: 44, weight: .light, design: .serif)
            nonisolated static let numeralXLBold: Font = .system(size: 44, weight: .bold, design: .serif)
            nonisolated static let numeralXXLLight: Font = .system(size: 46, weight: .light, design: .serif)
            nonisolated static let numeralXXLBold: Font = .system(size: 46, weight: .bold, design: .serif)
            nonisolated static let jumboBold: Font = .system(size: 52, weight: .bold, design: .serif)
            nonisolated static let jumboLLight: Font = .system(size: 56, weight: .light, design: .serif)
            nonisolated static let jumboXLLight: Font = .system(size: 60, weight: .light, design: .serif)
            nonisolated static let jumboXXLLight: Font = .system(size: 64, weight: .light, design: .serif)
            nonisolated static let colossalLight: Font = .system(size: 72, weight: .light, design: .serif)
            nonisolated static let colossalLBold: Font = .system(size: 80, weight: .bold, design: .serif)
            nonisolated static let colossalXLBold: Font = .system(size: 88, weight: .bold, design: .serif)
            nonisolated static let megaBold: Font = .system(size: 120, weight: .bold, design: .serif)
            nonisolated static let s16Semibold: Font = .system(size: 16, weight: .semibold, design: .serif)
            nonisolated static let s28Light: Font = .system(size: 28, weight: .light, design: .serif)
            nonisolated static let s34Bold: Font = .system(size: 34, weight: .bold, design: .serif)
        }

    }
}
