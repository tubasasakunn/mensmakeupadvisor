import SwiftUI
import UIKit

struct AdviceView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AdviceViewModel()

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, Theme.Spacing.md)
                    .padding(.horizontal, Theme.Spacing.xxl)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        chapterLabel
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        titleBlock
                            .padding(.top, Theme.Spacing.lg)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        HairlineDivider()
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        descriptionText
                            .padding(.top, Theme.Spacing.lg)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        AdviceViewfinderArea()
                            .padding(.top, Theme.Spacing.xxl)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        actionButtons
                            .padding(.top, Theme.Spacing.xl)
                            .padding(.horizontal, Theme.Spacing.xxl)

                        privacyCaption
                            .padding(.top, Theme.Spacing.lg)
                            .padding(.horizontal, Theme.Spacing.xxl)
                            .padding(.bottom, Theme.Spacing.xxxl)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraCaptureView(
                onCapture: { image in
                    viewModel.selectImage(image, appState: appState)
                    viewModel.showCamera = false
                },
                onCancel: {
                    viewModel.showCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .aid("advice_capture_view")
    }

    // MARK: - Navigation

    // 戻り先は AppState.captureOrigin に従う。
    // - 初回 (onboarding 完了直後): .onboarding に戻る
    // - Home 経由: .home に戻る
    // ラベルはどちらの場合でも「戻る」で統一し、行き先を読み上げる
    // accessibilityLabel だけ文脈に応じて切り替える。
    private var backDestination: AppScreen { appState.captureOrigin }
    private var backAccessibilityLabel: String {
        switch backDestination {
        case .home: "ホームに戻る"
        case .onboarding: "オンボーディングガイドに戻る"
        default: "戻る"
        }
    }

    private var navigationBar: some View {
        HStack {
            Button {
                Haptics.soft()
                appState.navigate(to: backDestination)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("戻る")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Theme.Text.primarySoft)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, 7)
                .glassEffect(.clear, in: .capsule)
            }
            .accessibilityLabel(backAccessibilityLabel)
            .aid("advice_back_button")

            Spacer()
        }
    }

    // MARK: - Header

    private var chapterLabel: some View {
        Text("CHAPTER 07 · SCAN")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Theme.Text.secondaryFaded)
            .kerning(2.8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("step one.")
                .font(.system(size: 44, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Theme.Text.primaryFaded)

            Text("まず、あなたの顔を\nちゃんと、知る。")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .lineSpacing(6)
        }
    }

    private var descriptionText: some View {
        Text("顔の比率・骨格・左右対称性を\n7つの指標で分析。あなただけの\nメイクアドバイスを導き出す。")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Theme.Text.primaryFaded)
            .lineSpacing(7)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            if AppEnvironment.useMockImagePicker {
                AdviceMockImagePicker { image in
                    viewModel.selectImage(image, appState: appState)
                }
            } else {
                GlassPrimaryButton(
                    title: "カメラで撮影する",
                    icon: "camera.fill",
                    accessibilityID: "advice_camera_button"
                ) {
                    Haptics.medium()
                    viewModel.showCamera = true
                }
            }
            GlassSecondaryButton(
                title: "サンプル画像で試す",
                icon: "photo",
                accessibilityID: "advice_sample_button"
            ) {
                Haptics.soft()
                viewModel.useSample(appState: appState)
            }
        }
    }

    // MARK: - Privacy Caption

    private var privacyCaption: some View {
        HStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 10))
            Text("端末内処理 · アップロードなし · 痕跡なし")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .kerning(1.2)
        }
        .foregroundStyle(Theme.Text.tertiary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview {
    AdviceView()
        .environment(AppState())
        .environment(\.analysisService, MockAnalysisService())
}
