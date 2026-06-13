import CoreGraphics

// アプリ全体の固定サイズ・トークン (frame 寸法)。
//
// **再利用されるサイズの唯一の真実**。View で `.frame(width: 44)` のような数値直書きを
// しないこと。Spacing / Radius と同じく「複数箇所で意味を共有するスケール」をここに集約する。
//
// 設計方針:
// - **値は現行のレイアウトをそのまま保持**している (純粋なリファクタ。視覚は変えない)。
// - 1 箇所でしか使わない真に固有な寸法 (特定コンポーネントの内在的な縦横比など) は、
//   ここには出さず、そのファイル内の `private enum Layout` に置く (スコープを閉じる)。
// - CoreGraphics の CGFloat のみ。SwiftUI 非依存に保つ。

extension Theme {
    enum Size {

        // MARK: - Stroke (罫線・区切り線・バーの太さ)

        enum Stroke {
            nonisolated static let hairline: CGFloat = 1
            nonisolated static let thin:     CGFloat = 1.5
            nonisolated static let regular:  CGFloat = 2
            nonisolated static let bold:     CGFloat = 3
        }

        // MARK: - Dot (インジケータ・凡例の点)

        enum Dot {
            nonisolated static let small:  CGFloat = 5
            nonisolated static let medium: CGFloat = 6
            nonisolated static let large:  CGFloat = 10
        }

        // MARK: - Control (円形ボタン・アイコンボタン・アバターの直径)

        enum Control {
            nonisolated static let circleSmall:  CGFloat = 30
            nonisolated static let circleMedium: CGFloat = 40
            // 標準タップ領域 / 画面ヘッダーの高さ
            nonisolated static let hitTarget:    CGFloat = 44
            nonisolated static let circleLarge:  CGFloat = 52
            nonisolated static let circleXLarge: CGFloat = 56
        }

        // MARK: - Column (行頭アイコン / 行末数値を縦に揃える固定幅スロット)

        enum Column {
            nonisolated static let narrow:   CGFloat = 18
            nonisolated static let icon:     CGFloat = 22
            nonisolated static let iconWide: CGFloat = 24
            nonisolated static let chapter:  CGFloat = 28
            nonisolated static let score:    CGFloat = 44
        }

        // MARK: - ShareCard (共有用に書き出すカードの絶対寸法)

        // SNS 共有画像として固定サイズで描く必要があるため Tokens 化して 1 箇所に集約する。
        enum ShareCard {
            nonisolated static let width:               CGFloat = 320
            nonisolated static let height:              CGFloat = 568
            nonisolated static let bodyHeight:          CGFloat = 220
            nonisolated static let diagnosisBodyHeight: CGFloat = 200
            nonisolated static let avatar:              CGFloat = 52
        }

        // MARK: - Canvas (アニメーション・スキャン領域の固定キャンバス)

        enum Canvas {
            // Onboarding Howto アニメーションの正方キャンバス
            nonisolated static let howto: CGFloat = 260
            // Analyzing のスキャン領域
            nonisolated static let scan:  CGFloat = 240
        }

        // MARK: - Line (Canvas / Shape の描画ストローク幅)

        // 顔メッシュ・評価線・区切りなどシェイプ描画の lineWidth。frame の Stroke とは
        // 別物 (こちらはサブポイントの細線を含む描画専用スケール)。
        enum Line {
            nonisolated static let hair: CGFloat = 0.3
            nonisolated static let faint: CGFloat = 0.4
            nonisolated static let thin: CGFloat = 0.5
            nonisolated static let light: CGFloat = 0.6
            nonisolated static let soft: CGFloat = 0.7
            nonisolated static let medium: CGFloat = 0.8
            nonisolated static let firm: CGFloat = 0.9
            nonisolated static let regular: CGFloat = 1
            nonisolated static let bold: CGFloat = 1.2
            nonisolated static let heavy: CGFloat = 2
            nonisolated static let thick: CGFloat = 4
            nonisolated static let chunky: CGFloat = 5
        }
    }
}
