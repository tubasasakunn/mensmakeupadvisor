import SwiftUI
import UIKit

// アプリ全体のデザイントークン (色)。
//
// **このファイルがアプリの色の唯一の真実**。
// View ファイルの中で `Color(...)`, `Color.X.opacity(...)`, `UIColor(...)`
// を新たに書かないこと。色を足したり調整したいときは、まずここに
// トークンを追加してから参照する。
//
// 設計方針:
// - 2 層構造。`Palette` が「具体的な色値」、`Theme` が「意味」を表す。
//   View からは `Theme.Surface.canvas` のように意味で参照する。
// - 一部 SwiftUI Color を直接受け取れない箇所 (UIGraphicsImageRenderer
//   での画像生成) では `Theme.UIKitColor.*` を使う。
// - Swift 6 strict concurrency に合わせ `nonisolated static let` で公開する。
// - Asset Catalog の Color Set はまだ採用していない (ダーク前提の単一テーマ)。
//   ライト/ダーク両対応が必要になったらここを動的解決に切り替える。
//
// 後方互換:
// - 既存の `Color.brandPrimary`, `Color.ivory` などの意匠名は
//   Color+Brand.swift で Theme のエイリアスとして残してある。

enum Theme {

    // MARK: - Surface (背景・カード面)

    enum Surface {
        nonisolated static let canvas           = Palette.canvas
        nonisolated static let sunken           = Palette.gray06
        nonisolated static let raised           = Palette.gray10
        nonisolated static let glassWeak        = Palette.whiteAlpha04
        // glass の暖色版。Onboarding カード等で ivory ベースの淡い半透明にしたいときに使う。
        nonisolated static let glassWeakIvory   = Palette.ivoryAlpha04
        nonisolated static let glassMedium      = Palette.whiteAlpha08
        nonisolated static let scrim            = Palette.blackAlpha50
        nonisolated static let labelBackdrop    = Palette.canvasAlpha60
        nonisolated static let imageDim         = Palette.canvasAlpha55
        nonisolated static let imageDimMedium   = Palette.canvasAlpha50
        nonisolated static let imageDimStrong   = Palette.canvasAlpha65
        nonisolated static let toastBackground  = Palette.ivoryAlpha92
        nonisolated static let shareCardOverlay = Palette.canvasAlpha38
        // Studio / Tutorial の画像プレートの絶対黒バックドロップ
        // (画像で覆われるが、画像のアスペクトが合わない端を埋める)
        nonisolated static let imageBackdrop    = Palette.black
    }

    // MARK: - Text (文字色)

    enum Text {
        // 主要・補助テキスト
        nonisolated static let primary       = Palette.ivory
        nonisolated static let secondary     = Palette.inkSecondary
        nonisolated static let tertiary      = Palette.inkTertiary

        // 明色ボタン / 明色面の上に乗せる文字
        nonisolated static let onAccent      = Palette.canvas
        nonisolated static let onAccentSoft  = Palette.canvasAlpha70

        // glass / 暗い面の上の柔らかい明色テキスト
        nonisolated static let primarySoft   = Palette.ivoryAlpha92
        nonisolated static let primaryFaded  = Palette.ivoryAlpha70
        nonisolated static let primarySubtle = Palette.ivoryAlpha60
        nonisolated static let primaryDim    = Palette.ivoryAlpha50

        // バッジ / ラベル
        nonisolated static let badgeLabel    = Palette.ivoryAlpha90
        nonisolated static let statValue     = Palette.ivoryAlpha85

        // 補助テキストの opacity 段階
        nonisolated static let secondaryFaded = Palette.inkSecondaryAlpha70
        nonisolated static let secondaryDim   = Palette.inkSecondaryAlpha60
    }

    // MARK: - Accent (ブランド・アクセント色)

    enum Accent {
        nonisolated static let primary        = Palette.bordeaux
        nonisolated static let primaryFaded   = Palette.bordeauxAlpha85
        nonisolated static let primarySoft    = Palette.bordeauxAlpha70
        nonisolated static let primarySubtle  = Palette.bordeauxAlpha28

        nonisolated static let highlight      = Palette.sulphur
        nonisolated static let eyebrow        = Palette.brownEyebrow
    }

    // MARK: - Line (区切り・枠線)

    enum Line {
        nonisolated static let subtle         = Palette.whiteAlpha12
        nonisolated static let strong         = Palette.whiteAlpha25
        nonisolated static let onAccentSubtle = Palette.canvasAlpha35

        // 標準ボタン outline (ink secondary 系)
        nonisolated static let outlineSoft    = Palette.inkSecondaryAlpha35
        nonisolated static let outlineMedium  = Palette.inkSecondaryAlpha40

        // 明色 outline (ivory 系)
        nonisolated static let outlineIvory   = Palette.ivoryAlpha35
        nonisolated static let outlineIvorySoft = Palette.ivoryAlpha25

        // 進捗バー塗りつぶし
        nonisolated static let progressFill   = Palette.ivoryAlpha70
    }

    // MARK: - Status (状態色)

    enum Status {
        nonisolated static let warning       = Palette.orangeAlpha85
        nonisolated static let warningBorder = Palette.orangeAlpha40
    }

    // MARK: - Plate (Studio / Tutorial / Analyzing の写真表示プレート)

    enum Plate {
        nonisolated static let placeholderEllipse  = Palette.ivoryAlpha25
        nonisolated static let beforeAfterDivider  = Palette.ivoryAlpha80
        nonisolated static let labelText           = Palette.ivoryAlpha90
        nonisolated static let renderingTint       = Palette.ivoryAlpha85
        nonisolated static let inProgressBadgeBg   = Palette.ivoryAlpha85
        nonisolated static let dashedEllipse       = Palette.ivoryAlpha30
        nonisolated static let cornerMark          = Palette.ivoryAlpha60
        nonisolated static let scanGridLine        = Palette.ivoryAlpha08
        nonisolated static let scanLineGlow        = Palette.bordeauxAlpha60
    }

    // MARK: - Mesh (顔メッシュ / 評価線描画)

    enum Mesh {
        nonisolated static let backdrop        = Palette.meshBackdrop
        nonisolated static let wireSubtle      = Palette.ivoryAlpha10
        nonisolated static let wireSegment     = Palette.ivoryAlpha28
        nonisolated static let landmarkDot     = Palette.ivoryAlpha65
        nonisolated static let placeholderGrid = Palette.ivoryAlpha12
        nonisolated static let savedLookOverlay = Palette.ivoryAlpha16
        // 円形チャートの目盛り (ScoreRing)
        nonisolated static let tickMark        = Palette.ivoryAlpha15
    }

    // MARK: - Annotation (Diagnosis の比率プレート・スコアアノテーション)

    enum Annotation {
        nonisolated static let primary      = Palette.ivoryAlpha95
        nonisolated static let accent       = Palette.bordeauxAlpha90
        nonisolated static let sub          = Palette.sulphurAlpha90
        nonisolated static let thirdsLine   = Palette.bordeauxAlpha85
        nonisolated static let fifthsLine   = Palette.sulphurAlpha85
    }

    // MARK: - Diagram (Onboarding 内の FaceDiagram 図解)

    enum Diagram {
        nonisolated static let faceOutline       = Palette.ivoryAlpha55
        nonisolated static let jawLine           = Palette.ivoryAlpha40
        nonisolated static let nose              = Palette.ivoryAlpha45
        nonisolated static let mouth             = Palette.ivoryAlpha40
        nonisolated static let dot               = Palette.ivoryAlpha12
        nonisolated static let region            = Palette.ivoryAlpha60
        nonisolated static let regionEye         = Palette.ivoryAlpha55
        nonisolated static let regionEyeHL       = Palette.bordeauxAlpha90
        nonisolated static let faceLayerSoft     = Palette.ivoryAlpha06
        nonisolated static let highlightArea     = Palette.ivoryAlpha28
        nonisolated static let highlightAreaSoft = Palette.ivoryAlpha30
        nonisolated static let shadowArea        = Palette.bordeauxAlpha22
    }

    // MARK: - Howto (Onboarding の Howto アニメーション)

    enum Howto {
        nonisolated static let canvas              = Palette.grayAlpha10
        nonisolated static let skinStroke          = Palette.howtoSkin
        nonisolated static let darkStroke          = Palette.howtoDark
        nonisolated static let basePink            = Palette.howtoPink
        nonisolated static let baseCyan            = Palette.howtoCyan
        nonisolated static let highlightGold       = Palette.howtoGold
        nonisolated static let highlightGoldFaded  = Palette.howtoGoldAlpha80
        nonisolated static let highlightCore       = Palette.white
        nonisolated static let highlightCoreBright = Palette.whiteAlpha95
        nonisolated static let shadowStroke        = Palette.howtoBrown
    }

    // MARK: - Placeholder (Onboarding step image の代替グレー)

    enum Placeholder {
        nonisolated static let stepBeforeSoft = Palette.gray15
        nonisolated static let stepBeforeMed  = Palette.gray18
        nonisolated static let stepAfterSoft  = Palette.gray22
        nonisolated static let stepAfterMed   = Palette.gray26
    }

    // MARK: - Step (Tutorial のレイヤーカラー: stepDots と base 専用色)

    enum Step {
        // base レイヤーのドットは ivory 50% (主役を譲るため弱め)
        nonisolated static let baseDot = Palette.ivoryAlpha50
        // 顔プレート上のステップタグラベル色
        nonisolated static let labelTag = Palette.ivoryAlpha60
    }

    // MARK: - Archive (Saved Look グリッドのオーバーレイ)

    enum Archive {
        // グリッドの右下に乗るグレード (S/A/B/C/D) の薄い ivory
        nonisolated static let gradeOverlay = Palette.ivoryAlpha60
    }

    // MARK: - Splash (起動画面)

    enum Splash {
        // 四隅の十字マーク
        nonisolated static let cornerMark = Palette.ivoryAlpha25
    }

    // MARK: - Spacing (アプリ全体の余白スケール)

    // 文学的・余白多めのレイアウトを基調にするための 8pt ベースのスケール。
    // マジックナンバー (`.padding(28)` など) は段階的にこちらへ寄せる。
    enum Spacing {
        nonisolated static let xs:   CGFloat = 4
        nonisolated static let sm:   CGFloat = 8
        nonisolated static let md:   CGFloat = 12
        nonisolated static let lg:   CGFloat = 16
        nonisolated static let xl:   CGFloat = 20
        nonisolated static let xxl:  CGFloat = 28
        nonisolated static let xxxl: CGFloat = 40
        nonisolated static let huge: CGFloat = 56
    }

    // MARK: - Radius (角丸スケール — Liquid Glass シェイプ前提)

    enum Radius {
        nonisolated static let pill: CGFloat = 999   // capsule 相当
        nonisolated static let xs:   CGFloat = 4
        nonisolated static let sm:   CGFloat = 8
        nonisolated static let md:   CGFloat = 14
        nonisolated static let lg:   CGFloat = 20
        nonisolated static let xl:   CGFloat = 28
        nonisolated static let xxl:  CGFloat = 36
    }

    // MARK: - Motion (アニメーション・タイミング)

    enum Motion {
        nonisolated static let quick:  Animation = .easeOut(duration: 0.2)
        nonisolated static let smooth: Animation = .easeInOut(duration: 0.35)
        nonisolated static let spring: Animation = .spring(duration: 0.45, bounce: 0.18)
        nonisolated static let lazy:   Animation = .easeInOut(duration: 0.6)
    }

    // MARK: - Ambient (Liquid Glass の屈折を見せるための暖色背景パレット)

    // 背景は単色ではなく、暖色のオーブを 2 つ配置した radial gradient にする。
    // これでガラスの「向こうに何かある」感が生まれる。
    enum Ambient {
        nonisolated static let backdrop      = Palette.canvas
        nonisolated static let backdropDeep  = Palette.canvasDeep
        nonisolated static let orbWarm       = Palette.bordeauxAlpha22
        nonisolated static let orbCool       = Palette.sulphurAlpha22
        nonisolated static let grain         = Palette.ivoryAlpha04
        nonisolated static let vignette      = Palette.blackAlpha50
    }

    // MARK: - UIKitColor (画像生成用の UIColor 版)

    // UIGraphicsImageRenderer で塗りつぶす際に SwiftUI Color では受け取れないため、
    // 対応する UIColor を別途定義する。`Theme.UIKitColor.*` で使う。
    enum UIKitColor {
        // 画像のないときの fallback プレースホルダ顔
        nonisolated static let placeholderFaceBackground = UIColor(red: 0.24, green: 0.21, blue: 0.18, alpha: 1.0)
        nonisolated static let placeholderFaceOval       = UIColor(white: 1.0, alpha: 0.45)
        nonisolated static let placeholderFaceLine       = UIColor(white: 1.0, alpha: 0.15)

        // Preview / サンプル画像生成用
        nonisolated static let previewCanvas             = UIColor(red: 0.20, green: 0.18, blue: 0.15, alpha: 1.0)

        // AdviceViewModel の useSample 用 (サンプル顔画像のレイヤー)
        nonisolated static let sampleBackground          = UIColor(red: 0.12, green: 0.11, blue: 0.09, alpha: 1.0)
        nonisolated static let sampleFace                = UIColor(red: 0.60, green: 0.50, blue: 0.40, alpha: 0.35)
        nonisolated static let sampleShadow              = UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 0.8)
        nonisolated static let sampleAccent              = UIColor(red: 0.20, green: 0.15, blue: 0.10, alpha: 0.7)
    }
}

// Palette / Color(hex:) は別ファイルに分離している:
//   - Shared/Theme/Palette.swift
//   - Shared/Extensions/Color+Hex.swift
