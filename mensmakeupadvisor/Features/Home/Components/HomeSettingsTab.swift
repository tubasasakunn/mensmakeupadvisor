import SwiftData
import SwiftUI

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
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .kerning(3)
            .foregroundStyle(Theme.Text.secondaryFaded)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("身嗜みの設定。")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
            Text("読みもの、記録、このアプリのこと。")
                .font(.system(size: 12))
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
            .font(.system(size: 10, weight: .medium, design: .monospaced))
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
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isDestructive ? Theme.Accent.primaryFaded : Theme.Text.primarySoft)
                    .frame(width: 22, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.ivory)
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Text.tertiary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
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
        try? modelContext.save()
    }

    private func clearCapturedCache() {
        appState.capturedImage = nil
        appState.renderedImage = nil
        appState.analysisResult = nil
        LatestFaceMeshStore.clear()
        Task { await appState.makeupEngine.reset() }
    }
}

// MARK: - About Sheet

// このアプリのことを 1 枚にまとめた静的シート。バージョン・要旨・プライバシー・著作。
// 将来項目が増えたら別ファイルに分けるが、現状は数行なので同梱で十分。
private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
    }

    var body: some View {
        ZStack {
            LuxeBackground(intensity: 0.4)
            VStack(spacing: 0) {
                ScreenHeader(
                    variant: .sheet,
                    kicker: "ABOUT",
                    backAccessibilityLabel: "閉じる",
                    backAccessibilityID: "about_close",
                    onBack: { dismiss() }
                )
                .padding(.top, Theme.Spacing.sm)

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        title
                        HairlineDivider()
                        statement
                        privacy
                        credits
                        version
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("a quiet study in")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .kerning(2.5)
                .foregroundStyle(Theme.Text.secondaryFaded)
            Text("The Better Self.")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
        }
    }

    private var statement: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("このアプリのこと")
            Text("紳士の身嗜みを、もう一段階。\n顔の比率と骨格を診て、あなたに合う\nメイクの手順を導く小さなアトリエ。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(5)
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("プライバシー")
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .padding(.top, 2)
                Text("撮影画像と診断結果はすべて端末内で処理されます。サーバーへのアップロード・解析の外部送信は一切行いません。")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .lineSpacing(5)
            }
        }
    }

    private var credits: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            sectionTitle("クレジット")
            Text("顔ランドマーク検出に MediaPipe FaceMesh を使用しています。Liquid Glass デザインは iOS 26 SDK の機能を利用しています。")
                .font(.system(size: 13))
                .foregroundStyle(Theme.Text.primaryFaded)
                .lineSpacing(5)
        }
    }

    private var version: some View {
        HStack {
            Text("Version")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.Text.tertiary)
            Spacer()
            Text("\(appVersion) (\(appBuild))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(Theme.Text.secondaryFaded)
        }
        .padding(.top, Theme.Spacing.lg)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .kerning(1.5)
            .foregroundStyle(Theme.Text.primaryFaded)
    }
}

#Preview {
    HomeSettingsTab()
        .environment(AppState())
        .modelContainer(for: [SavedLook.self], inMemory: true)
}
