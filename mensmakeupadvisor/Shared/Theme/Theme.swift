import SwiftUI

// アプリ全体のデザイントークン (色)。
//
// 設計方針:
// - 2 層構造。`Palette` が「具体的な色値」、`Theme` が「意味」を表す。
//   View からは `Theme.Surface.canvas` のように意味で参照する。
// - 1 色 = 1 つの定義場所。インラインの `Color(white:)`, `Color.white.opacity()`
//   などは禁止。新規箇所は必ず Theme トークンを使う。
// - Swift 6 strict concurrency に合わせ `nonisolated static let` で公開する。
// - Asset Catalog の Color Set はまだ採用していない (ダーク前提の単一テーマ)。
//   ライト/ダーク両対応が必要になったらここを動的解決に切り替える。
//
// 移行ポリシー:
// - 既存の `Color.brandPrimary`, `Color.ivory` などの意匠名は
//   Color+Brand.swift で Theme のエイリアスとして残してある。
//   新規 PR からは Theme 直参照を優先する。

enum Theme {

    // MARK: - Surface (背景・カード面)

    enum Surface {
        // アプリ全体の最下層背景 (ほぼ黒に近い濃いセピア)
        nonisolated static let canvas        = Palette.canvas

        // canvas より少し沈んだ面。画像プレースホルダなど。
        nonisolated static let sunken        = Palette.gray06

        // canvas より少し浮かせた面。リプレース可能なグレースケール下地。
        nonisolated static let raised        = Palette.gray10

        // 薄い半透明オーバーレイ。カード・チップなど僅かな elevation 表現に。
        nonisolated static let glassWeak     = Palette.whiteAlpha04

        // 中強度の半透明オーバーレイ。インタラクティブなボタン / モックピッカー。
        nonisolated static let glassMedium   = Palette.whiteAlpha08

        // モーダル背後の暗幕。
        nonisolated static let scrim         = Palette.blackAlpha50

        // 画像の上に置くラベルの背景 (可読性確保, 60% 不透明)。
        nonisolated static let labelBackdrop = Palette.canvasAlpha60

        // 画像のうえに線・テキスト等のオーバーレイを描くときに、画像を
        // 軽く沈める半透明レイヤ (55%)。画像はまだ視認できる強さ。
        nonisolated static let imageDim      = Palette.canvasAlpha55

        // 同上のさらに強いダウンミックス (65%)。比率線などの線情報が多いとき。
        nonisolated static let imageDimStrong = Palette.canvasAlpha65

        // 半透明の明色トースト / ヒント背景 (92% ivory)。
        nonisolated static let toastBackground = Palette.ivoryAlpha92
    }

    // MARK: - Text (文字色)

    enum Text {
        // 主要テキスト (明色)。
        nonisolated static let primary   = Palette.ivory

        // 補助テキスト。
        nonisolated static let secondary = Palette.inkSecondary

        // キャプション・補足。Glass 上では使わない (コントラスト不足)。
        nonisolated static let tertiary  = Palette.inkTertiary

        // 明色ボタンの上に乗せる文字色 (canvas に揃える)。
        nonisolated static let onAccent  = Palette.canvas

        // glass / 暗い面の上に乗せる、主要より少し柔らかい明色テキスト。
        nonisolated static let primarySoft  = Palette.ivoryAlpha92

        // 明色ボタン / 明色トースト上で「副題」位置に使う暗色テキスト。
        nonisolated static let onAccentSoft = Palette.canvasAlpha70
    }

    // MARK: - Accent (ブランド・アクセント色)

    enum Accent {
        // ブランド主色 (ボルドー)。
        nonisolated static let primary   = Palette.bordeaux

        // 中グレード B 表現に使う黄系。
        nonisolated static let highlight = Palette.sulphur

        // メイク領域の眉色 (アーカイブサムネ等)。
        nonisolated static let eyebrow   = Palette.brownEyebrow
    }

    // MARK: - Line (区切り・枠線)

    enum Line {
        // 細い区切り線 (12% 白)。
        nonisolated static let subtle = Palette.whiteAlpha12

        // 強調された枠線 (25% 白)。ボトムバーの outline 等。
        nonisolated static let strong = Palette.whiteAlpha25

        // 明色面 (トースト等) の上で使う控えめな枠線 (35% canvas)。
        nonisolated static let onAccentSubtle = Palette.canvasAlpha35
    }

    // MARK: - Status (状態色)

    enum Status {
        // テスト/モックモード等の注意喚起。
        nonisolated static let warning       = Color.orange.opacity(0.85)
        nonisolated static let warningBorder = Color.orange.opacity(0.40)
    }
}

// MARK: - Palette (具体的な色値の集約)

// View からは直接参照しない。Theme 経由で使う。
// 色を入れ替えるときはここだけ書き換える。
enum Palette {
    // ベースカラー
    nonisolated static let canvas        = Color(hex: 0x0E0E0C)
    nonisolated static let canvasAlpha35 = Color(hex: 0x0E0E0C, opacity: 0.35)
    nonisolated static let canvasAlpha55 = Color(hex: 0x0E0E0C, opacity: 0.55)
    nonisolated static let canvasAlpha60 = Color(hex: 0x0E0E0C, opacity: 0.60)
    nonisolated static let canvasAlpha65 = Color(hex: 0x0E0E0C, opacity: 0.65)
    nonisolated static let canvasAlpha70 = Color(hex: 0x0E0E0C, opacity: 0.70)

    nonisolated static let ivory        = Color(hex: 0xF4EFE6)
    nonisolated static let ivoryAlpha92 = Color(hex: 0xF4EFE6, opacity: 0.92)
    nonisolated static let bordeaux     = Color(hex: 0xB8332A)
    nonisolated static let sulphur      = Color(red: 0.90, green: 0.85, blue: 0.40)
    nonisolated static let inkSecondary = Color(hex: 0x9A958C)
    nonisolated static let inkTertiary  = Color(hex: 0x5A554C)
    nonisolated static let brownEyebrow = Color(red: 0.55, green: 0.35, blue: 0.20)

    // グレースケール下地 (canvas の濃淡)
    nonisolated static let gray06       = Color(white: 0.06)
    nonisolated static let gray10       = Color(white: 0.10)

    // 半透明ホワイト
    nonisolated static let whiteAlpha04 = Color.white.opacity(0.04)
    nonisolated static let whiteAlpha08 = Color.white.opacity(0.08)
    nonisolated static let whiteAlpha12 = Color.white.opacity(0.12)
    nonisolated static let whiteAlpha25 = Color.white.opacity(0.25)

    // 半透明ブラック
    nonisolated static let blackAlpha50 = Color.black.opacity(0.50)
}

// MARK: - Helpers

extension Color {
    // `Color(hex: 0xRRGGBB)` のヘルパ。デザイナーからの色指定をそのまま書ける。
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
