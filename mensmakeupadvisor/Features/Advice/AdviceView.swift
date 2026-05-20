import SwiftUI
import UIKit

struct AdviceView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AdviceViewModel()

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar
                    .padding(.top, 12)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        chapterLabel
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        titleBlock
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                        HairlineDivider()
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        descriptionText
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                        AdviceViewfinderArea()
                            .padding(.top, 28)
                            .padding(.horizontal, 24)

                        actionButtons
                            .padding(.top, 24)
                            .padding(.horizontal, 24)

                        privacyCaption
                            .padding(.top, 16)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 48)
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

    private var navigationBar: some View {
        HStack {
            Button {
                appState.navigate(to: .onboarding)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("ガイドに戻る")
                        .font(.system(size: 13, weight: .regular))
                }
                .foregroundStyle(Color.inkSecondary)
            }
            .accessibilityLabel("オンボーディングガイドに戻る")
            .aid("advice_back_button")

            Spacer()
        }
    }

    // MARK: - Header

    private var chapterLabel: some View {
        Text("CHAPTER 07 · SCAN")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkSecondary)
            .kerning(2.5)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("step one.")
                .font(.system(size: 42, weight: .light, design: .serif))
                .italic()
                .foregroundStyle(Color.brandPrimary)

            Text("まず、あなたの顔を\nちゃんと、知る。")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .italic()
                .foregroundStyle(Color.ivory)
                .lineSpacing(4)
        }
    }

    private var descriptionText: some View {
        Text("顔の比率・骨格・左右対称性を\n7つの指標で分析。あなただけの\nメイクアドバイスを導き出す。")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color.inkSecondary)
            .lineSpacing(6)
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if AppEnvironment.useMockImagePicker {
                AdviceMockImagePicker { image in
                    viewModel.selectImage(image, appState: appState)
                }
            } else {
                primaryButton
            }
            sampleButton
        }
    }

    private var primaryButton: some View {
        Button {
            viewModel.showCamera = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text("カメラで撮影する")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .kerning(0.5)
                Text("→")
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
            }
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.ivory)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .aid("advice_camera_button")
    }

    private var sampleButton: some View {
        Button {
            viewModel.useSample(appState: appState)
        } label: {
            Text("サンプル画像で試す")
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.ivory)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .hairlineBorder(Theme.Line.outlineIvory, cornerRadius: 2)
        }
        .aid("advice_sample_button")
    }

    // MARK: - Privacy Caption

    private var privacyCaption: some View {
        Text("— 端末内処理 · アップロードなし · 痕跡なし —")
            .font(.system(size: 10, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.inkTertiary)
            .kerning(1.0)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview {
    AdviceView()
        .environment(AppState())
        .environment(\.analysisService, MockAnalysisService())
}
