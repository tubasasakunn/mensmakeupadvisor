import SwiftUI

// Archive グリッドのカードをタップしたときに出る詳細ボトムシート。
// メッシュ図 + 適用ゾーン一覧 + 強度表示 + 編集 / 削除アクション。
struct SavedLookDetailSheet: View {
    let look: SavedLook
    let onApply: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    headerRow
                    thumbnail
                    GlassCard(radius: Theme.Radius.lg, padding: Theme.Spacing.lg) {
                        appliedZoneList
                    }
                    GlassCard(radius: Theme.Radius.lg, padding: Theme.Spacing.lg) {
                        intensityRows
                    }
                    actionRow
                }
                .padding(Theme.Spacing.xl)
            }
        }
        .confirmationDialog(
            "このルックを削除しますか？",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                onDelete()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("削除すると元に戻せません。")
        }
        .aid("home_archive_detail_sheet")
    }

    private var headerRow: some View {
        HStack {
            Text(look.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
            Spacer()
            if look.totalScore > 0 {
                Text("\(look.totalScore) 点")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var thumbnail: some View {
        SavedLookMeshThumbnail(look: look, geometry: SavedLookMeshGeometry.makeLatest())
            .frame(maxWidth: 320)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md)
                    .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
            )
    }

    private var appliedZoneList: some View {
        VStack(alignment: .leading, spacing: 10) {
            zoneRow(title: "ハイライト", names: Array(look.highlightAreaSet))
            zoneRow(title: "シェーディング", names: Array(look.shadowAreaSet))
            zoneRow(title: "目元", names: Array(look.eyeAreaSet))
            if let raw = look.eyebrowTypeRaw, !raw.isEmpty {
                zoneRow(title: "眉のかたち", names: [raw])
            }
        }
    }

    private func zoneRow(title: String, names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
            Text(names.isEmpty ? "—" : names.map(MakeupAreaLabel.display).joined(separator: " · "))
                .font(.system(size: 13))
                .foregroundStyle(Color.ivory)
        }
    }

    private var intensityRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("強さ")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSecondary)
            intensityRow("ベース",       look.base)
            intensityRow("ハイライト",   look.highlight)
            intensityRow("シェーディング", look.shadow)
            intensityRow("目元",         look.eye)
        }
    }

    private func intensityRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
            Spacer()
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.ivory)
        }
    }

    private var actionRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            GlassSecondaryButton(
                title: "削除",
                icon: "trash",
                accessibilityID: "home_archive_detail_delete"
            ) {
                showDeleteConfirmation = true
            }

            GlassPrimaryButton(
                title: "このルックを編集",
                accessibilityID: "home_archive_detail_apply",
                action: onApply
            )
        }
    }
}

#Preview {
    SavedLookDetailSheet(
        look: SavedLook(
            highlightAreas: ["base_t-zone", "base_c-zone"],
            shadowAreas: ["omonaga-lower"],
            eyeAreas: ["eyeshadow_base", "tear_bag", "eyeliner"],
            eyebrowTypeRaw: "natural"
        ),
        onApply: {}, onDelete: {}
    )
    .background(Color.appBackground)
}
