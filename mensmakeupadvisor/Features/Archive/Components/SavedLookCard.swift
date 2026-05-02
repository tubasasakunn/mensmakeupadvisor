import SwiftData
import SwiftUI

struct SavedLookCard: View {
    let look: SavedLook
    let index: Int
    let onApply: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageArea
            infoArea
        }
        .aid("archive_look_card_\(look.id)")
    }

    // MARK: - Subviews

    // intensity 0–100 → opacity 0.08–0.55 の非線形マッピング
    private func intensityOpacity(_ value: Double, scale: Double = 100.0) -> Double {
        let normalized = min(max(value / scale, 0), 1)
        return 0.08 + normalized * 0.47
    }

    private var imageArea: some View {
        ZStack(alignment: .topLeading) {
            // ベース: プリセットカラーのトーン
            Color(red: 0.12, green: 0.10, blue: 0.08)
                .aspectRatio(4.0 / 5.0, contentMode: .fit)

            // ハイライトグラデーション（上→中）
            LinearGradient(
                colors: [
                    Color.ivory.opacity(intensityOpacity(look.highlight, scale: 80)),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            .aspectRatio(4.0 / 5.0, contentMode: .fit)

            // ベースの肌色オーバーレイ（中央）
            RadialGradient(
                colors: [
                    Color(red: 0.75, green: 0.60, blue: 0.48).opacity(intensityOpacity(look.base, scale: 80)),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 60
            )
            .aspectRatio(4.0 / 5.0, contentMode: .fit)

            // シャドウ（下端）
            LinearGradient(
                colors: [
                    Color.black.opacity(0.55),
                    Color.clear
                ],
                startPoint: .bottom,
                endPoint: .init(x: 0.5, y: 0.55)
            )
            .aspectRatio(4.0 / 5.0, contentMode: .fit)

            // プリセットラベル（左上）
            VStack {
                HStack {
                    Text(presetLabel)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.ivory.opacity(0.7))
                        .kerning(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    Spacer()
                }
                Spacer()
            }

            // スコア（右下）
            if look.totalScore > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(look.totalScore)")
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory.opacity(0.6))
                            .padding(8)
                    }
                }
            }
        }
    }

    private var infoArea: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Text("n°\(String(format: "%02d", index))")
                    .font(.system(size: 18, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)

                Spacer()

                Button {
                    onShare()
                } label: {
                    Text("↑")
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 22, height: 22)
                }
                .aid("archive_share_\(look.id)")

                Button {
                    onDelete()
                } label: {
                    Text("✕")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color.inkSecondary)
                        .frame(width: 22, height: 22)
                }
                .aid("archive_delete_\(look.id)")
            }

            Text(look.createdAt, format: .dateTime.month().day())
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)

            Button {
                onApply()
            } label: {
                Text("APPLY →")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.ivory)
                    .kerning(1)
            }
            .aid("archive_apply_\(look.id)")
        }
        .padding(12)
    }

    // MARK: - Helpers

    private var presetLabel: String {
        guard let pid = look.presetID,
              let preset = MakeupPreset.all.first(where: { $0.id == pid }) else {
            return "CUSTOM"
        }
        return preset.label.uppercased()
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 0) {
        SavedLookCard(
            look: SavedLook(
                id: "preview-1",
                createdAt: .now,
                presetID: "natural",
                totalScore: 72,
                faceShape: "tamago",
                base: 22, highlight: 18, shadow: 14, eye: 12, eyebrow: 28
            ),
            index: 1,
            onApply: {},
            onDelete: {},
            onShare: {}
        )
        SavedLookCard(
            look: SavedLook(
                id: "preview-2",
                createdAt: .now,
                presetID: "mode",
                totalScore: 85,
                faceShape: "tamago",
                base: 28, highlight: 32, shadow: 35, eye: 32, eyebrow: 45
            ),
            index: 2,
            onApply: {},
            onDelete: {},
            onShare: {}
        )
    }
    .background(Color.appBackground)
    .modelContainer(for: [SavedLook.self], inMemory: true)
}
