import SwiftUI
import UIKit

// ライブ "ミラーモード"。フロントカメラの映像に、いま組んでいる化粧 (composition) を
// 毎フレーム合成して表示する。Studio から「鏡モードで実践」で開き、戻ると元の画面へ。
//
// 注意: カメラ・MediaPipe・合成はシミュレータで動かないため、--mock-mode では
// Studio の合成済み画像 (renderedImage) を静的に出すプレースホルダにする。
// 実機ではフレームレート (合成負荷) と向き (CameraFrameProcessor の orientation) が
// 調整点になる。
struct MirrorView: View {
    @Environment(AppState.self) private var appState
    @State private var camera = CameraSessionController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraLayer

            VStack(spacing: 0) {
                header
                    .padding(.top, Theme.Spacing.sm)
                Spacer(minLength: 0)
                caption
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.bottom, Theme.Spacing.xxxl)
            }
        }
        .task { await startIfPossible() }
        .onDisappear { camera.stop() }
        .aid("mirror_view")
    }

    // MARK: - Camera layer

    @ViewBuilder
    private var cameraLayer: some View {
        if AppEnvironment.useMockCamera {
            mockLayer
        } else {
            switch camera.status {
            case .running:
                if let frame = camera.renderedFrame {
                    Image(uiImage: frame)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .aid("mirror_live_frame")
                } else {
                    loadingLayer(message: "顔を画面に映してください")
                }
            case .denied:
                deniedLayer
            case .failed(let message):
                messageLayer(icon: "exclamationmark.triangle", title: "カメラを起動できません", body: message)
            case .idle, .configuring:
                loadingLayer(message: "カメラを準備中…")
            }
        }
    }

    // モック: Studio で合成済みの化粧画像をそのまま「鏡像」に見立てて表示する。
    private var mockLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let display = appState.renderedImage ?? appState.capturedImage {
                Image(uiImage: display)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            }
            Text("[MOCK] ミラーモード")
                .font(Theme.Typography.Data.baseMedium)
                .foregroundStyle(Theme.Status.warning)
                .padding(.vertical, 6)
                .padding(.horizontal, Theme.Spacing.md)
                .background(Theme.Surface.labelBackdrop, in: .capsule)
                .padding(.top, 100)
                .aid("mirror_mock_label")
        }
    }

    private func loadingLayer(message: String) -> some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Color.ivory)
            Text(message)
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Theme.Text.primaryFaded)
        }
    }

    private var deniedLayer: some View {
        messageLayer(
            icon: "lock.shield",
            title: "カメラへのアクセスが必要です",
            body: "設定アプリでカメラの使用を許可すると、鏡モードを利用できます。",
            actionTitle: "設定を開く",
            action: openSettings
        )
    }

    private func messageLayer(
        icon: String,
        title: String,
        body: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        GlassCard(radius: Theme.Radius.xl, padding: Theme.Spacing.xxl) {
            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: icon)
                    .font(Theme.Typography.UI.s36UltraLight)
                    .foregroundStyle(Theme.Text.secondary)
                Text(title)
                    .font(Theme.Typography.Display.s16Semibold)
                    .foregroundStyle(Color.ivory)
                Text(body)
                    .font(Theme.Typography.UI.subheadline)
                    .foregroundStyle(Theme.Text.primaryFaded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                if let actionTitle, let action {
                    GlassPrimaryButton(
                        title: actionTitle,
                        accessibilityID: "mirror_open_settings_button"
                    ) { action() }
                    .padding(.top, Theme.Spacing.sm)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // MARK: - Chrome

    private var header: some View {
        ScreenHeader(
            variant: .push,
            kicker: "MIRROR",
            backAccessibilityLabel: "戻る",
            backAccessibilityID: "mirror_back_button",
            onBack: {
                camera.stop()
                appState.navigate(to: appState.navigation.mirrorOrigin)
            }
        )
    }

    private var caption: some View {
        Text("鏡を見ながら、いまの仕上がりを確認できます")
            .font(Theme.Typography.UI.subheadlineMedium)
            .foregroundStyle(Color.ivory)
            .padding(.vertical, Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Theme.Surface.labelBackdrop, in: .capsule)
            .aid("mirror_caption")
    }

    // MARK: - Actions

    private func startIfPossible() async {
        guard !AppEnvironment.useMockCamera else { return }
        await camera.start(composition: appState.composition)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Preview

#Preview {
    MirrorView()
        .environment(AppState())
}
