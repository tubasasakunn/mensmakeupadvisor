import OSLog
import SwiftData
import SwiftUI

private let settingsLog = Logger(subsystem: "com.tubasasakun.mensmakeupadvisor", category: "HomeSettings")

// アトリエタブ。コアループに入らない裏方の操作 (ガイド再読・データ削除・About) を集約。
// 他の Home タブの体裁 (kicker mono + serif italic title + HairlineDivider) を踏襲する。
struct HomeSettingsTab: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var savedLooks: [SavedLook]

    @State private var showRereadConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var showClearCacheConfirmation = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            LuxeBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    kickerLabel
                        .padding(.top, Theme.Spacing.xxxl)
                    titleSection
                        .padding(.top, Theme.Spacing.md)
                    HairlineDivider()
                        .padding(.top, Theme.Spacing.xxl)

                    recordSection
                        .padding(.top, Theme.Spacing.xxl)
                    HairlineDivider()
                        .padding(.top, Theme.Spacing.xl)

                    aboutSection
                        .padding(.top, Theme.Spacing.xl)
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.huge)
            }
        }
        .confirmationDialog(
            "ガイドをもう一度読みますか？",
            isPresented: $showRereadConfirmation,
            titleVisibility: .visible
        ) {
            Button("読み始める") {
                Haptics.medium()
                appState.navigate(to: .onboarding)
            }
            Button("やめる", role: .cancel) {}
        } message: {
            Text("最初の章から読み直します。途中で目次から章ジャンプもできます。")
        }
        .confirmationDialog(
            "保存ルックを全て削除しますか？",
            isPresented: $showDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("全て削除する", role: .destructive) {
                Haptics.warning()
                deleteAllLooks()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(savedLooks.count) 件のルックが削除されます。元に戻せません。")
        }
        .confirmationDialog(
            "撮影画像のキャッシュを消しますか？",
            isPresented: $showClearCacheConfirmation,
            titleVisibility: .visible
        ) {
            Button("キャッシュを消す", role: .destructive) {
                Haptics.warning()
                clearCapturedCache()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("直近の顔写真・診断結果・顔メッシュが消えます。保存ルックは残ります。")
        }
        .sheet(isPresented: $showAbout) {
            AboutSheet()
                .presentationBackground(Theme.Ambient.backdrop)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .aid("home_settings_tab")
    }

    // MARK: - Header

    private var kickerLabel: some View {
        Text("ATELIER")
            .font(Theme.Typography.Data.baseMedium)
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("身嗜みの設定。")
                .font(Theme.Typography.Display.heroXLBold)
                .italic()
                .foregroundStyle(Color.ivory)
            Text("読みもの、記録、このアプリのこと。")
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
        }
    }

    // MARK: - Sections

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("RECORD")
            row(
                title: "ガイドをもう一度読む",
                detail: "最初の章から",
                systemImage: "book.pages",
                accessibilityID: "settings_row_reread"
            ) {
                Haptics.soft()
                showRereadConfirmation = true
            }
            row(
                title: "保存したルックを全て消す",
                detail: savedLooks.isEmpty ? "0 件" : "\(savedLooks.count) 件",
                systemImage: "trash",
                accessibilityID: "settings_row_delete_looks",
                isDestructive: true,
                isEnabled: !savedLooks.isEmpty
            ) {
                Haptics.soft()
                showDeleteAllConfirmation = true
            }
            row(
                title: "撮影画像のキャッシュを消す",
                detail: hasCachedCapture ? "あり" : "なし",
                systemImage: "photo.badge.arrow.down",
                accessibilityID: "settings_row_clear_cache",
                isDestructive: true,
                isEnabled: hasCachedCapture
            ) {
                Haptics.soft()
                showClearCacheConfirmation = true
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionLabel("ABOUT")
            row(
                title: "このアプリについて",
                detail: appVersion,
                systemImage: "info.circle",
                accessibilityID: "settings_row_about"
            ) {
                Haptics.soft()
                showAbout = true
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.Data.smallMedium)
            .kerning(2.5)
            .foregroundStyle(Theme.Text.tertiary)
            .padding(.bottom, Theme.Spacing.xs)
    }

    // 共通行レイアウト。Glass の上に Glass を重ねない (タブ全体は LuxeBackground 上)。
    private func row(
        title: String,
        detail: String,
        systemImage: String,
        accessibilityID: String,
        isDestructive: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: systemImage)
                    .font(Theme.Typography.UI.bodyLargeRegular)
                    .foregroundStyle(isDestructive ? Theme.Accent.primaryFaded : Theme.Text.primarySoft)
                    .frame(width: Theme.Size.Column.icon, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.UI.bodyMedium)
                        .foregroundStyle(Color.ivory)
                    Text(detail)
                        .font(Theme.Typography.UI.footnote)
                        .foregroundStyle(Theme.Text.tertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.UI.footnoteSemibold)
                    .foregroundStyle(Theme.Text.tertiary)
            }
            .padding(.vertical, Theme.Spacing.md)
            .overlay(alignment: .bottom) { HairlineDivider() }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .aid(accessibilityID)
    }

    // MARK: - Helpers

    private var hasCachedCapture: Bool {
        appState.capturedImage != nil
            || appState.analysisResult != nil
            || LatestFaceMeshStore.load() != nil
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private func deleteAllLooks() {
        for look in savedLooks { modelContext.delete(look) }
        do {
            try modelContext.save()
        } catch {
            settingsLog.error("deleteAllLooks: 全削除の保存に失敗 — \(String(describing: error), privacy: .public)")
        }
    }

    private func clearCapturedCache() {
        appState.capturedImage = nil
        appState.renderedImage = nil
        appState.analysisResult = nil
        LatestFaceMeshStore.clear()
        Task { await appState.makeupEngine.reset() }
    }
}

// AboutSheet は Features/Home/Components/AboutSheet.swift に分離。

#Preview {
    HomeSettingsTab()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
