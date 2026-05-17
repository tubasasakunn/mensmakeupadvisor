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

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            ScrollView { contentStack }
        }
        .sheet(item: $selected) { look in
            SavedLookDetailSheet(
                look: look,
                onApply: { handleApply(look) },
                onDelete: { handleDelete(look) }
            )
            .presentationBackground(Color.appBackground)
        }
        .aid("home_archive_tab")
    }

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
                .padding(.top, 32)
                .padding(.horizontal, 28)
            titleSection
                .padding(.top, 12)
                .padding(.horizontal, 28)
            Rectangle().fill(Color.lineColor).frame(height: 1)
                .padding(.top, 20)
                .padding(.horizontal, 28)

            if savedLooks.isEmpty {
                emptyState
            } else {
                grid.padding(.top, 16)
            }
        }
        .padding(.bottom, 80)
    }

    private var headerSection: some View {
        Text("ARCHIVE · YOUR LOOKS")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("your archive.")
                .font(.system(size: 38, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("\(savedLooks.count) looks saved")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("♡")
                .font(.system(size: 36))
                .foregroundStyle(Color.inkSecondary)
            Text("まだ、保存はありません")
                .font(.system(size: 14, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
            Text("CREATE タブからルックを作って\nスタジオで保存してください。")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .aid("home_archive_empty")
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(savedLooks) { look in
                gridCell(for: look)
            }
        }
        .padding(.horizontal, 2)
    }

    private func gridCell(for look: SavedLook) -> some View {
        Button { selected = look } label: {
            SavedLookMeshThumbnail(look: look)
                .overlay(alignment: .bottomTrailing) {
                    if look.totalScore > 0 {
                        Text(grade(for: look.totalScore))
                            .font(.system(size: 11, weight: .light, design: .serif))
                            .italic()
                            .foregroundStyle(Color.ivory.opacity(0.6))
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
