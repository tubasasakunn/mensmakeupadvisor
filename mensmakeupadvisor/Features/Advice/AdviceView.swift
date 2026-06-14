import PhotosUI
import SwiftUI
import UIKit

struct AdviceView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AdviceViewModel()
    // ライブラリ選択。PhotosPicker はプロセス外で動くため写真ライブラリの
    // 使用許可 (Info.plist) は不要。選択後に Data → UIImage に変換して流す。
    @State private var pickedItem: PhotosPickerItem?

    var body: some View {
        ZStack {
            LuxeBackground()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, Theme.Spacing.md)

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

                        actionButtons
                            .padding(.top, Theme.Spacing.xxxl)
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
        .onChange(of: pickedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    viewModel.selectImage(image, appState: appState)
                } else {
                    viewModel.errorMessage = "画像を読み込めませんでした。別の写真をお試しください。"
                }
                pickedItem = nil
            }
        }
        .alert(
            "読み込みエラー",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .aid("advice_capture_view")
    }

    // MARK: - Navigation

    // 戻り先は AppState.captureOrigin に従う。
    // - 初回 (onboarding 完了直後): .onboarding に戻る
    // - Home 経由: .home に戻る
    // 視覚ラベルは「戻る」一語、accessibilityLabel だけ文脈に応じて切り替える。
    private var backDestination: AppScreen { appState.captureOrigin }
    private var backAccessibilityLabel: String {
        switch backDestination {
        case .home: "ホームに戻る"
        case .onboarding: "オンボーディングガイドに戻る"
        default: "戻る"
        }
    }

    private var navigationBar: some View {
        ScreenHeader(
            variant: .push,
            kicker: "SCAN",
            backAccessibilityLabel: backAccessibilityLabel,
            backAccessibilityID: "advice_back_button",
            onBack: { appState.navigate(to: backDestination) }
        )
    }

    // MARK: - Header

    private var chapterLabel: some View {
        Text("CHAPTER 07 · SCAN")
            .font(Theme.Typography.Data.smallRegular)
            .foregroundStyle(Theme.Text.secondaryFaded)
            .kerning(2.8)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("step one.")
                .font(Theme.Typography.Display.numeralXLLight)
                .italic()
                .foregroundStyle(Theme.Text.primaryFaded)

            Text("まず、あなたの顔を\nちゃんと、知る。")
                .font(Theme.Typography.Display.heroBold)
                .italic()
                .foregroundStyle(Color.ivory)
                .lineSpacing(6)
        }
    }

    private var descriptionText: some View {
        Text("顔の比率・骨格・左右対称性を\n7つの指標で分析。あなただけの\nメイクアドバイスを導き出す。")
            .font(Theme.Typography.UI.calloutRegular)
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
                libraryButton
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

    // ライブラリから写真を選ぶ。GlassSecondaryButton と同じ見た目に揃える
    // (PhotosPicker は独自ボタンなので label を手組みする)。
    private var libraryButton: some View {
        PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "photo.on.rectangle")
                    .font(Theme.Typography.UI.bodyRegular)
                Text("ライブラリから選ぶ")
                    .font(Theme.Typography.UI.bodyMedium)
                    .kerning(0.3)
            }
            .foregroundStyle(Theme.Text.primarySoft)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.Surface.panel, in: .capsule)
            .overlay(
                Capsule().stroke(Theme.Line.outlineIvorySoft, lineWidth: Theme.Size.Line.light)
            )
        }
        .aid("advice_library_button")
    }

    // MARK: - Privacy Caption

    private var privacyCaption: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: "lock.shield")
                .font(Theme.Typography.UI.caption)
            Text("端末内処理 · アップロードなし · 痕跡なし")
                .font(Theme.Typography.Data.smallRegular)
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
