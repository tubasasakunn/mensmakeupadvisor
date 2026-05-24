import SwiftUI

// Archive グリッドのカードをタップしたときに出る詳細ボトムシート。
// レイアウトは ScreenHeader sheet バリアントで統一:
//   左: ×（閉じる）
//   右: 共有アイコン + 「編集」テキストボタン
// body 末尾の primary CTA は「今の自分で試す」、secondary は「削除」。
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

            VStack(spacing: 0) {
                header
                    .padding(.top, Theme.Spacing.sm)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        meta
                        thumbnail
                        appliedZoneList
                            .frame(maxWidth: .infinity, alignment: .leading)
                        HairlineDivider()
                        intensityRows
                            .frame(maxWidth: .infinity, alignment: .leading)
                        actionRow
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
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

    // MARK: - Header

    private var header: some View {
        ScreenHeader(
            variant: .sheet,
            kicker: "ARCHIVE",
            backAccessibilityLabel: "閉じる",
            backAccessibilityID: "home_archive_detail_close",
            onBack: { dismiss() },
            trailing: {
                HStack(spacing: Theme.Spacing.sm) {
                    shareButton
                    editButton
                }
            }
        )
    }

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
            .frame(width: 30, height: 30)
            .glassEffect(.clear, in: .circle)
        }
        .accessibilityLabel(isPreparingShare ? "共有画像を準備中" : "このルックを共有する")
        .aid("home_archive_detail_share")
        .disabled(isPreparingShare)
    }

    // 「編集 = Studio で再調整」。スタジオ直行 (Tutorial スキップ)。
    private var editButton: some View {
        Button {
            Haptics.medium()
            onApply()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10, weight: .semibold))
                Text("編集")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, 7)
            .glassEffect(.clear, in: .capsule)
        }
        .accessibilityLabel("このルックをスタジオで編集する")
        .aid("home_archive_detail_apply")
    }

    // MARK: - Content

    private var meta: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    if let title = look.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory)
                    }
                    Text(look.createdAt, format: .dateTime.year().month().day().hour().minute())
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkSecondary)
                }
                Spacer()
                if look.totalScore > 0 {
                    Text("\(look.totalScore) 点")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkSecondary)
                }
            }
            if let memo = look.memo, !memo.isEmpty {
                Text(memo)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

    // body 末尾の CTA 2 段。
    // primary: 「今の自分で試す」= 別の顔で試着 (capture → analyze → studio 直行・保存しない)
    // secondary: 「削除」= 破壊的、押しづらい配置に。
    private var actionRow: some View {
        VStack(spacing: Theme.Spacing.md) {
            GlassPrimaryButton(
                title: "今の自分で試す",
                icon: "camera.fill",
                accessibilityID: "home_archive_detail_try"
            ) {
                Haptics.medium()
                onTry()
            }

            GlassSecondaryButton(
                title: "削除",
                icon: "trash",
                accessibilityID: "home_archive_detail_delete"
            ) {
                Haptics.warning()
                showDeleteConfirmation = true
            }
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Share

    private func shareLook() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        // Archive には顔写真がないため、シェアカードのビジュアル領域 (320×220)
        // にメッシュサムネを焼き込んで「写真欠落」の空っぽカードを避ける。
        let meshImage = renderMeshHero()
        let card = MakeupShareCardView(
            renderedImage: meshImage,
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

    private func renderMeshHero() -> UIImage? {
        let hero = ZStack {
            // 透けると上のシェアカードオーバーレイで真っ黒に潰れるので、
            // ここで明示的に背景を敷く。
            Theme.Surface.raised
            SavedLookMeshThumbnail(look: look, geometry: SavedLookMeshGeometry.makeLatest())
                .aspectRatio(1, contentMode: .fit)
                .padding(.vertical, 8)
        }
        .frame(width: 320, height: 220)
        return ShareHelper.render(hero)
    }

    // 保存済みのスライダー値・ゾーン集合から MakeupComposition を復元する。
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
