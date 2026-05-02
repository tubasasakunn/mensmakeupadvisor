import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLook.createdAt, order: .reverse) private var savedLooks: [SavedLook]
    @State private var viewModel = ArchiveViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, 8)

                    titleSection
                        .padding(.top, 28)

                    Rectangle()
                        .fill(Color.lineColor)
                        .frame(height: 1)
                        .padding(.top, 20)
                        .padding(.bottom, 28)

                    if savedLooks.isEmpty {
                        emptyState
                    } else {
                        looksGrid
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 100)
            }
        }
        .aid("archive_view")
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack {
            Button {
                appState.navigate(to: .studio)
            } label: {
                Text("← STUDIO")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .kerning(1.5)
            }

            Spacer()

            Text("THE ARCHIVE")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.ivory)
                .kerning(2)

            Spacer()

            // バランス用スペーサー（同幅）
            Text("← STUDIO")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.clear)
                .kerning(1.5)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("your archive.")
                .font(.system(size: 42, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("保存したルック.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1.5)
                .padding(.top, 2)

            Text("\(savedLooks.count) looks saved")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(1)
                .padding(.top, 4)
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

            Text("スタジオでルックをアーカイブすると\nここに表示されます。")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.inkSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .aid("archive_empty_state")
    }

    private func shareLook(_ look: SavedLook) {
        let card = LookShareCardView(look: look)
        if let image = ShareHelper.render(card) {
            ShareHelper.present([image])
        }
    }

    private var looksGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 1),
                GridItem(.flexible(), spacing: 1)
            ],
            spacing: 1
        ) {
            ForEach(Array(savedLooks.enumerated()), id: \.element.id) { index, look in
                SavedLookCard(
                    look: look,
                    index: index + 1,
                    onApply: { viewModel.applyLook(look, appState: appState) },
                    onDelete: { viewModel.deleteLook(look, modelContext: modelContext) },
                    onShare: { shareLook(look) }
                )
                .background(Color(white: 0.06))
            }
        }
        .overlay(Rectangle().stroke(Color.lineColor, lineWidth: 1))
        .aid("archive_looks_grid")
    }
}

// MARK: - Preview

#Preview("With Looks") {
    ArchiveView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}

#Preview("Empty State") {
    ArchiveView()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
