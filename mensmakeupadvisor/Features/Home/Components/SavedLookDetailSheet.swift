import SwiftUI

// Archive グリッドのカードをタップしたときに出る詳細ボトムシート。
// メッシュ図 + 適用ゾーン一覧 + 強度表示 + 編集 / 削除アクション。
struct SavedLookDetailSheet: View {
    let look: SavedLook
    let onApply: () -> Void
    let onDelete: () -> Void

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
        .aid("home_archive_detail_sheet")
    }

    private var headerRow: some View {
        HStack {
            Text(look.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1)
            Spacer()
            if look.totalScore > 0 {
                Text("\(look.totalScore)pt")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
            }
        }
    }

    private var thumbnail: some View {
        SavedLookMeshThumbnail(look: look, mesh: LatestFaceMeshStore.load())
            .frame(maxWidth: 320)
            .frame(maxWidth: .infinity)
            .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
    }

    private var appliedZoneList: some View {
        VStack(alignment: .leading, spacing: 10) {
            zoneRow(title: "HIGHLIGHT", names: Array(look.highlightAreaSet))
            zoneRow(title: "SHADOW",    names: Array(look.shadowAreaSet))
            zoneRow(title: "EYE",       names: Array(look.eyeAreaSet))
            if let raw = look.eyebrowTypeRaw, !raw.isEmpty {
                zoneRow(title: "BROW", names: [raw])
            }
        }
    }

    private func zoneRow(title: String, names: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
            Text(names.isEmpty ? "—" : names.map(MakeupAreaLabel.display).joined(separator: " · "))
                .font(.system(size: 12))
                .foregroundStyle(Color.ivory)
        }
    }

    private var intensityRows: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("INTENSITY")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
            intensityRow("BASE",      look.base)
            intensityRow("HIGHLIGHT", look.highlight)
            intensityRow("SHADOW",    look.shadow)
            intensityRow("EYE",       look.eye)
        }
    }

    private func intensityRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1.2)
            Spacer()
            Text(String(format: "%.0f", value))
                .font(.system(size: 14, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button(action: onDelete) {
                Text("削除")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(Rectangle().stroke(Color.inkSecondary.opacity(0.35), lineWidth: 1))
            }
            .aid("home_archive_detail_delete")

            Button(action: onApply) {
                Text("このルックを編集 →")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color.appBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.ivory)
            }
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
