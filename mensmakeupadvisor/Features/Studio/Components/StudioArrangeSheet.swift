import SwiftUI

// Studio から開く「アレンジ」シート。Studio 本体は仕上がり確認専用に保ち、
// プリセット比較・カラー調整といった任意の微調整はここに集約する。
struct StudioArrangeSheet: View {
    @Environment(\.dismiss) private var dismiss

    enum Mode: String, CaseIterable, Identifiable {
        case compare, color
        var id: String { rawValue }
        var label: String {
            switch self {
            case .compare: "プリセット比較"
            case .color:   "カラー"
            }
        }
    }

    @State private var mode: Mode = .compare

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                variant: .sheet,
                kicker: "ARRANGE",
                backAccessibilityLabel: "閉じる",
                backAccessibilityID: "studio_arrange_close_button",
                onBack: { dismiss() }
            )
            .padding(.top, Theme.Spacing.sm)

            modePicker
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.top, Theme.Spacing.md)

            ScrollView {
                Group {
                    switch mode {
                    case .compare:
                        PresetCompareView(onApply: { dismiss() })
                    case .color:
                        ColorCustomizeView(onApply: { dismiss() })
                    }
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, Theme.Spacing.xxxl)
            }
        }
        .aid("studio_arrange_sheet")
    }

    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(Mode.allCases) { m in
                Button {
                    mode = m
                } label: {
                    Text(m.label)
                        .font(Theme.Typography.UI.calloutSemibold)
                        .foregroundStyle(mode == m ? Theme.Text.onAccent : Color.ivory)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(mode == m ? Color.ivory : Color.clear, in: .capsule)
                }
                .aid("studio_arrange_tab_\(m.rawValue)")
            }
        }
        .padding(Theme.Spacing.xs)
        .background(Theme.Surface.panel, in: .capsule)
        .overlay(Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.thin))
    }
}
