import SwiftData
import SwiftUI

// 保存ルックのグリッド表示。Instagram フィードのように 3 列で並べ、
// サムネは「どこに化粧を入れたか」を示すメッシュ図 (SavedLookMeshThumbnail)。
struct HomeArchiveTab: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLook.createdAt, order: .reverse) private var savedLooks: [SavedLook]
    @State private var viewModel = ArchiveViewModel()
    @State private var selected: SavedLook?
    // 最新メッシュは一度だけ復元し、全グリッドセルのサムネ下地に使い回す。
    @State private var geometry: SavedLookMeshGeometry? = SavedLookMeshGeometry.makeLatest()

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
    ]

    var body: some View {
        ZStack {
            LuxeBackground()
            ScrollView { contentStack }
        }
        .sheet(item: $selected) { look in
            SavedLookDetailSheet(
                look: look,
                onApply: { handleApply(look) },
                onDelete: { handleDelete(look) }
            )
            .presentationBackground(Theme.Ambient.backdrop)
        }
        .aid("home_archive_tab")
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            kickerLabel
                .padding(.top, Theme.Spacing.xxxl)
                .padding(.horizontal, Theme.Spacing.xxl)
            titleSection
                .padding(.top, Theme.Spacing.md)
                .padding(.horizontal, Theme.Spacing.xxl)
            HairlineDivider()
                .padding(.top, Theme.Spacing.xxl)
                .padding(.horizontal, Theme.Spacing.xxl)

            if savedLooks.isEmpty {
                emptyState
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.top, Theme.Spacing.xl)
            } else {
                grid
                    .padding(.top, Theme.Spacing.xl)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .padding(.bottom, Theme.Spacing.huge)
    }

    private var kickerLabel: some View {
        Text("ARCHIVE")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("マイ・コレクション")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)

            Text(savedLooks.isEmpty ? "保存ゼロ件" : "保存 \(savedLooks.count) 件")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSecondary)
        }
    }

    private var emptyState: some View {
        GlassCard(radius: Theme.Radius.xl, padding: Theme.Spacing.xxl) {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "heart")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(Theme.Text.secondary)
                Text("まだ保存したルックがありません")
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.ivory)
                Text("「撮影」タブから自分の顔を撮って、\nスタジオで気に入った仕上がりを保存できます。")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }
            .frame(maxWidth: .infinity)
        }
        .aid("home_archive_empty")
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(savedLooks) { look in
                gridCell(for: look)
            }
        }
    }

    private func gridCell(for look: SavedLook) -> some View {
        Button {
            Haptics.soft()
            selected = look
        } label: {
            SavedLookMeshThumbnail(look: look, geometry: geometry)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .stroke(Theme.Line.outlineIvorySoft, lineWidth: 0.5)
                )
                .overlay(alignment: .bottomTrailing) {
                    if look.totalScore > 0 {
                        Text(grade(for: look.totalScore))
                            .font(.system(size: 12, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .glassEffect(.regular, in: .capsule)
                            .padding(6)
                    }
                }
                .contentShape(Rectangle())
        }
        .aid("home_archive_card_\(look.id)")
    }

    // MARK: - Actions

    private func handleApply(_ look: SavedLook) {
        viewModel.applyLook(look, appState: appState)
        appState.skipTutorialOnNextFlow = true
        selected = nil
    }

    private func handleDelete(_ look: SavedLook) {
        viewModel.deleteLook(look, modelContext: modelContext)
        selected = nil
    }

    private func grade(for score: Int) -> String {
        switch score {
        case 85...: "S"
        case 75...: "A"
        case 65...: "B"
        case 55...: "C"
        default:    "D"
        }
    }
}

#Preview {
    HomeArchiveTab()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
