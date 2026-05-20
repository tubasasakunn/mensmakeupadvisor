import UIKit

// アプリ全体で使う触覚フィードバックの薄いラッパー。
// 各画面で UIImpactFeedbackGenerator を直接組まずに済むよう集約する。
//
// iOS HIG: 重要な操作や状態変化には控えめな触覚を添えると "意図が伝わった" 感が出る。
// 過剰使用は逆効果なので「保存」「撮影開始」「リセット」のような節目で使う。
enum Haptics {
    // 軽いタップ感。CTA タップなど日常的な操作向け。
    @MainActor
    static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }

    // しっかりした感触。保存・確定など「完了した」感を出したいとき。
    @MainActor
    static func medium() {
        let g = UIImpactFeedbackGenerator(style: .medium)
        g.impactOccurred()
    }

    // 注意喚起。リセット確認や、エラー時の振動寄り。
    @MainActor
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // 成功通知。Save 完了時に。
    @MainActor
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // 選択ティック。プリセット切替や mode 切替に。
    @MainActor
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
