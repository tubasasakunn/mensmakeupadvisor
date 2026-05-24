import SwiftUI

// Archive グリッドのカードをタップしたときに出る詳細ボトムシート。
// メッシュ図 + 適用ゾーン一覧 + 強度表示 + 共有 / 編集 / 削除アクション。
struct SavedLookDetailSheet: View {
    let look: SavedLook
    let onApply: () -> Void
    let onTry: () -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var isPreparingShare = false

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    headerRow
                    thumbnail
                    // 詳細セクションは白っぽい Glass を避けて素のレイアウトで読ませる
                    appliedZoneList
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HairlineDivider()
                    intensityRows
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                Haptics.warning()
                onDelete()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("削除すると元に戻せません。")
        }
        .aid("home_archive_detail_sheet")
    }

    private var headerRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(look.createdAt, format: .dateTime.year().month().day().hour().minute())
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
            Spacer()
            if look.totalScore > 0 {
                Text("\(look.totalScore) 点")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSecondary)
            }
            shareButton
            closeButton
        }
    }

    // Studio と同じく右上の小さな共有アイコン。
    // 共有内容は保存ルックから再構築した MakeupShareCardView。
    private var shareButton: some View {
        Button {
            Haptics.soft()
            Task { await shareLook() }
        } label: {
            Group {
                if isPreparingShare {
                    ProgressView()
                        .tint(Theme.Text.primarySoft)
                        .scaleEffect(0.6)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.Text.primarySoft)
                }
            }
            .frame(width: 28, height: 28)
            .glassEffect(.clear, in: .circle)
            .overlay(
                Circle().strokeBorder(Theme.Line.outlineIvorySoft, lineWidth: 0.6)
            )
        }
        .accessibilityLabel(isPreparingShare ? "共有画像を準備中" : "このルックを共有する")
        .aid("home_archive_detail_share")
        .disabled(isPreparingShare)
    }

    private func shareLook() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        let card = MakeupShareCardView(
            renderedImage: nil,
            capturedImage: nil,
            composition: composition(from: look),
            result: archivedResult(from: look),
            mode: .styled,
            date: look.createdAt
        )
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    // 保存済みのスライダー値・ゾーン集合から MakeupComposition を復元する。
    // ArchiveViewModel.applyLook と同じ復元ロジックをここでも使う。
    private func composition(from look: SavedLook) -> MakeupComposition {
        MakeupCompositionBuilder.make(
            highlightAreas: look.highlightAreaSet,
            shadowAreas: look.shadowAreaSet,
            eyeAreas: look.eyeAreaSet,
            browType: EyebrowApplier.BrowType(rawValue: look.eyebrowTypeRaw ?? ""),
            base: Float(look.base / 100),
            highlight: Float(look.highlight / 100),
            shadow: Float(look.shadow / 100),
            eye: Float(look.eye / 100)
        )
    }

    // シェアカードに必要なのは faceShape ラベルと grade だけ。
    // スコアは保存していないので「総合点 1 つ」のミニ AnalysisResult を組む。
    private func archivedResult(from look: SavedLook) -> AnalysisResult? {
        guard look.totalScore > 0 else { return nil }
        let shape = FaceShape(rawValue: look.faceShape) ?? .tamago
        let score = FaceScore(name: "総合", score: look.totalScore, advice: "")
        return AnalysisResult(faceShape: shape, scores: [score])
    }

    // シートを閉じてアーカイブ画面に戻る明示的な出口。
    // .sheet(item:) 経由なのでスワイプダウンでも閉じられるが、
    // 「戻る術が無い」と感じさせないため可視のボタンを置く。
    private var closeButton: some View {
        Button {
            Haptics.soft()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Text.primarySoft)
                .frame(width: 28, height: 28)
                .glassEffect(.clear, in: .circle)
                .overlay(
                    Circle().strokeBorder(Theme.Line.outlineIvorySoft, lineWidth: 0.6)
                )
        }
        .accessibilityLabel("閉じる")
        .aid("home_archive_detail_close")
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
        VStack(spacing: Theme.Spacing.sm) {
            // メインは「試す = いま撮った顔で見てみる」。
            // 過去の自分の顔ではなく今日の顔に当てたい欲求が一番強いはずなので
            // プロミネントに置く。
            GlassPrimaryButton(
                title: "今の自分で試す",
                icon: "camera.fill",
                accessibilityID: "home_archive_detail_try"
            ) {
                Haptics.medium()
                onTry()
            }

            HStack(spacing: Theme.Spacing.md) {
                GlassSecondaryButton(
                    title: "削除",
                    icon: "trash",
                    accessibilityID: "home_archive_detail_delete"
                ) {
                    Haptics.warning()
                    showDeleteConfirmation = true
                }

                GlassSecondaryButton(
                    title: "編集",
                    icon: "slider.horizontal.3",
                    accessibilityID: "home_archive_detail_apply"
                ) {
                    Haptics.medium()
                    onApply()
                }
            }
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
        onApply: {}, onTry: {}, onDelete: {}
    )
    .background(Color.appBackground)
}
