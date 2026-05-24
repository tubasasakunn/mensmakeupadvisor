import SwiftUI

// View からは直接参照しない。Theme 経由で使う。
// 色を入れ替えるときはここだけ書き換える。
enum Palette {

    // MARK: ベース色 (solid)
    nonisolated static let canvas        = Color(hex: 0x0E0E0C)
    // canvas の深いバリエーション。ambient gradient の外周用。
    nonisolated static let canvasDeep    = Color(hex: 0x070705)
    nonisolated static let ivory         = Color(hex: 0xF4EFE6)
    nonisolated static let bordeaux      = Color(hex: 0xB8332A)
    nonisolated static let sulphur       = Color(red: 0.90, green: 0.85, blue: 0.40)
    nonisolated static let inkSecondary  = Color(hex: 0x9A958C)
    nonisolated static let inkTertiary   = Color(hex: 0x5A554C)
    nonisolated static let brownEyebrow  = Color(red: 0.55, green: 0.35, blue: 0.20)
    nonisolated static let white         = Color.white
    nonisolated static let black         = Color.black

    // メッシュ図解の暗いベース
    nonisolated static let meshBackdrop  = Color(red: 0.10, green: 0.09, blue: 0.08)

    // Howto アニメ用色 (記憶しやすい RGB)
    nonisolated static let howtoSkin     = Color(red: 0.612, green: 0.482, blue: 0.439)
    nonisolated static let howtoDark     = Color(red: 0.129, green: 0.129, blue: 0.129)
    nonisolated static let howtoPink     = Color(red: 0.913, green: 0.118, blue: 0.388)
    nonisolated static let howtoCyan     = Color(red: 0.0,   green: 0.737, blue: 0.831)
    nonisolated static let howtoGold     = Color(red: 1.0,   green: 0.961, blue: 0.616)
    nonisolated static let howtoGoldAlpha80 = Color(red: 1.0, green: 0.961, blue: 0.616, opacity: 0.8)
    nonisolated static let howtoBrown    = Color(red: 0.365, green: 0.227, blue: 0.161)

    // 純白の opacity バリエーション (Howto グラデーション)
    nonisolated static let whiteAlpha95  = Color.white.opacity(0.95)

    // MARK: canvas (黒系) の半透明
    nonisolated static let canvasAlpha35 = Color(hex: 0x0E0E0C, opacity: 0.35)
    nonisolated static let canvasAlpha38 = Color(hex: 0x0E0E0C, opacity: 0.38)
    nonisolated static let canvasAlpha50 = Color(hex: 0x0E0E0C, opacity: 0.50)
    nonisolated static let canvasAlpha55 = Color(hex: 0x0E0E0C, opacity: 0.55)
    nonisolated static let canvasAlpha60 = Color(hex: 0x0E0E0C, opacity: 0.60)
    nonisolated static let canvasAlpha65 = Color(hex: 0x0E0E0C, opacity: 0.65)
    nonisolated static let canvasAlpha70 = Color(hex: 0x0E0E0C, opacity: 0.70)

    // MARK: ivory (明色) の半透明
    nonisolated static let ivoryAlpha04  = Color(hex: 0xF4EFE6, opacity: 0.04)
    nonisolated static let ivoryAlpha06  = Color(hex: 0xF4EFE6, opacity: 0.06)
    nonisolated static let ivoryAlpha08  = Color(hex: 0xF4EFE6, opacity: 0.08)
    nonisolated static let ivoryAlpha10  = Color(hex: 0xF4EFE6, opacity: 0.10)
    nonisolated static let ivoryAlpha12  = Color(hex: 0xF4EFE6, opacity: 0.12)
    nonisolated static let ivoryAlpha15  = Color(hex: 0xF4EFE6, opacity: 0.15)
    nonisolated static let ivoryAlpha16  = Color(hex: 0xF4EFE6, opacity: 0.16)
    nonisolated static let ivoryAlpha25  = Color(hex: 0xF4EFE6, opacity: 0.25)
    nonisolated static let ivoryAlpha28  = Color(hex: 0xF4EFE6, opacity: 0.28)
    nonisolated static let ivoryAlpha30  = Color(hex: 0xF4EFE6, opacity: 0.30)
    nonisolated static let ivoryAlpha35  = Color(hex: 0xF4EFE6, opacity: 0.35)
    nonisolated static let ivoryAlpha40  = Color(hex: 0xF4EFE6, opacity: 0.40)
    nonisolated static let ivoryAlpha45  = Color(hex: 0xF4EFE6, opacity: 0.45)
    nonisolated static let ivoryAlpha50  = Color(hex: 0xF4EFE6, opacity: 0.50)
    nonisolated static let ivoryAlpha55  = Color(hex: 0xF4EFE6, opacity: 0.55)
    nonisolated static let ivoryAlpha60  = Color(hex: 0xF4EFE6, opacity: 0.60)
    nonisolated static let ivoryAlpha65  = Color(hex: 0xF4EFE6, opacity: 0.65)
    nonisolated static let ivoryAlpha70  = Color(hex: 0xF4EFE6, opacity: 0.70)
    nonisolated static let ivoryAlpha80  = Color(hex: 0xF4EFE6, opacity: 0.80)
    nonisolated static let ivoryAlpha85  = Color(hex: 0xF4EFE6, opacity: 0.85)
    nonisolated static let ivoryAlpha90  = Color(hex: 0xF4EFE6, opacity: 0.90)
    nonisolated static let ivoryAlpha92  = Color(hex: 0xF4EFE6, opacity: 0.92)
    nonisolated static let ivoryAlpha95  = Color(hex: 0xF4EFE6, opacity: 0.95)

    // MARK: bordeaux (ブランド赤) の半透明
    nonisolated static let bordeauxAlpha22 = Color(hex: 0xB8332A, opacity: 0.22)
    nonisolated static let bordeauxAlpha28 = Color(hex: 0xB8332A, opacity: 0.28)
    nonisolated static let bordeauxAlpha60 = Color(hex: 0xB8332A, opacity: 0.60)
    nonisolated static let bordeauxAlpha70 = Color(hex: 0xB8332A, opacity: 0.70)
    nonisolated static let bordeauxAlpha85 = Color(hex: 0xB8332A, opacity: 0.85)
    nonisolated static let bordeauxAlpha90 = Color(hex: 0xB8332A, opacity: 0.90)

    // MARK: sulphur (黄系) の半透明
    nonisolated static let sulphurAlpha22 = Color(red: 0.90, green: 0.85, blue: 0.40, opacity: 0.22)
    nonisolated static let sulphurAlpha85 = Color(red: 0.90, green: 0.85, blue: 0.40, opacity: 0.85)
    nonisolated static let sulphurAlpha90 = Color(red: 0.90, green: 0.85, blue: 0.40, opacity: 0.90)

    // MARK: inkSecondary (副グレー) の半透明
    nonisolated static let inkSecondaryAlpha35 = Color(hex: 0x9A958C, opacity: 0.35)
    nonisolated static let inkSecondaryAlpha40 = Color(hex: 0x9A958C, opacity: 0.40)
    nonisolated static let inkSecondaryAlpha60 = Color(hex: 0x9A958C, opacity: 0.60)
    nonisolated static let inkSecondaryAlpha70 = Color(hex: 0x9A958C, opacity: 0.70)

    // MARK: グレースケール下地 (canvas の濃淡)
    nonisolated static let gray06 = Color(white: 0.06)
    nonisolated static let gray10 = Color(white: 0.10)
    nonisolated static let gray15 = Color(white: 0.15)
    nonisolated static let gray18 = Color(white: 0.18)
    nonisolated static let gray22 = Color(white: 0.22)
    nonisolated static let gray26 = Color(white: 0.26)
    nonisolated static let grayAlpha10 = Color.gray.opacity(0.10)

    // MARK: その他の半透明
    nonisolated static let whiteAlpha04 = Color.white.opacity(0.04)
    nonisolated static let whiteAlpha08 = Color.white.opacity(0.08)
    nonisolated static let whiteAlpha12 = Color.white.opacity(0.12)
    nonisolated static let whiteAlpha25 = Color.white.opacity(0.25)
    nonisolated static let blackAlpha50 = Color.black.opacity(0.50)

    // MARK: 警告色 (system orange)
    nonisolated static let orangeAlpha40 = Color.orange.opacity(0.40)
    nonisolated static let orangeAlpha85 = Color.orange.opacity(0.85)
}
