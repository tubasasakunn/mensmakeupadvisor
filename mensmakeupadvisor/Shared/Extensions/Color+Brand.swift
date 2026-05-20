import SwiftUI

// 旧 API 互換のための薄いエイリアス層。
//
// `Color.brandPrimary` 等の意匠名は既存コードから多数参照されているため
// 後方互換として残す。実体は Shared/Theme/Theme.swift にあり、
// 新規コードでは `Theme.Accent.primary` のような意味ベースの参照を使うこと。
extension Color {
    nonisolated static let brandPrimary  = Theme.Accent.primary
    nonisolated static let ivory         = Theme.Text.primary
    nonisolated static let appBackground = Theme.Surface.canvas
    nonisolated static let inkSecondary  = Theme.Text.secondary
    nonisolated static let inkTertiary   = Theme.Text.tertiary
    nonisolated static let sulphur       = Theme.Accent.highlight
    nonisolated static let lineColor     = Theme.Line.subtle
    nonisolated static let lineStrong    = Theme.Line.strong
}
