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
            Color.appBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerRow
                    thumbnail
                    appliedZoneList
                    intensityRows
                    actionRow
                }
                .padding(24)
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
            .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
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
        HStack(spacing: 12) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .medium))
                    Text("削除")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Color.inkSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(Rectangle().stroke(Theme.Line.outlineSoft, lineWidth: 1))
            }
            .accessibilityLabel("このルックを削除")
            .aid("home_archive_detail_delete")

            Button(action: onApply) {
                HStack(spacing: 6) {
                    Text("このルックを編集")
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color.appBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.ivory)
            }
            .accessibilityLabel("このルックをスタジオで編集")
            .aid("home_archive_detail_apply")
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
