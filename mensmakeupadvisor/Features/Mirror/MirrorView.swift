import AVFoundation
import SwiftUI
import UIKit

// ライブ "ミラーモード"。フロントカメラの鏡像映像に、塗る位置のガイドを重ねる。
// Studio から「鏡モードで実践」で開き、戻ると元の画面へ復帰する。
//
// 注意: カメラはシミュレータで動作しないため、--mock-mode では静的プレースホルダを
// 出す (Maestro / スクリーンショット用)。実機での向き・座標の微調整が前提。
struct MirrorView: View {
    @Environment(AppState.self) private var appState
    @State private var camera = CameraSessionController()

    // 鏡像プレビュー上に固定で出すモック顔 (中央)。実機が無い環境での確認用。
    private let mockFace = FaceObservation(
        boundingBox: CGRect(x: 0.28, y: 0.24, width: 0.44, height: 0.5)
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            cameraLayer

            VStack(spacing: 0) {
                header
                    .padding(.top, Theme.Spacing.sm)
                Spacer(minLength: 0)
                legend
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
                ZStack {
                    CameraPreviewView(session: camera.session)
                        .ignoresSafeArea()
                    MirrorGuideOverlay(face: camera.face)
                        .ignoresSafeArea()
                    if camera.face == nil { faceHint }
                }
            case .denied:
                deniedLayer
            case .failed(let message):
                messageLayer(icon: "exclamationmark.triangle", title: "カメラを起動できません", body: message)
            case .idle, .configuring:
                loadingLayer
            }
        }
    }

    private var mockLayer: some View {
        ZStack {
            RadialGradient(
                colors: [Theme.Surface.raised, .black],
                center: .center, startRadius: 40, endRadius: 420
            )
            .ignoresSafeArea()

            Ellipse()
                .stroke(Theme.Plate.dashedEllipse, style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
                .frame(width: 220, height: 300)

            MirrorGuideOverlay(face: mockFace)
                .ignoresSafeArea()

            Text("[MOCK] ミラーモード")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(Theme.Status.warning)
                .padding(.top, 180)
                .aid("mirror_mock_label")
        }
    }

    private var faceHint: some View {
        VStack {
            Spacer()
            Text("顔を画面の中央に合わせてください")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.ivory)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Surface.labelBackdrop, in: .capsule)
            Spacer().frame(height: 160)
        }
        .aid("mirror_face_hint")
    }

    private var loadingLayer: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .tint(Color.ivory)
            Text("カメラを準備中…")
                .font(.system(size: 12))
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
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(Theme.Text.secondary)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.ivory)
                Text(body)
                    .font(.system(size: 12))
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

    // 色 → 意味の凡例。
    private var legend: some View {
        HStack(spacing: Theme.Spacing.xl) {
            legendChip(color: .sulphur, label: "ハイライト")
            legendChip(color: Theme.Accent.primary, label: "シェーディング")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Surface.labelBackdrop, in: .capsule)
        .aid("mirror_legend")
    }

    private func legendChip(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color.opacity(0.5))
                .overlay(Circle().stroke(color, lineWidth: 1))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.ivory)
        }
    }

    // MARK: - Actions

    private func startIfPossible() async {
        guard !AppEnvironment.useMockCamera else { return }
        await camera.start()
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
