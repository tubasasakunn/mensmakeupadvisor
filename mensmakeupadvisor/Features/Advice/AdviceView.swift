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

                        dividerLine
                            .padding(.top, 20)
                            .padding(.horizontal, 24)

                        descriptionText
                            .padding(.top, 16)
                            .padding(.horizontal, 24)

                        viewfinderArea
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
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePickerView { image in
                viewModel.selectImage(image, appState: appState)
                viewModel.showImagePicker = false
            }
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
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                    Text("BACK")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .kerning(1.5)
                }
                .foregroundStyle(Color.inkSecondary)
            }
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

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.lineColor)
            .frame(height: 1)
    }

    private var descriptionText: some View {
        Text("顔の比率・骨格・左右対称性を\n7つの指標で分析。あなただけの\nメイクアドバイスを導き出す。")
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(Color.inkSecondary)
            .lineSpacing(6)
    }

    // MARK: - Viewfinder

    private var viewfinderArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.03))
                .frame(height: 280)

            // ダッシュ枠（楕円）
            Ellipse()
                .stroke(
                    style: StrokeStyle(lineWidth: 1, dash: [6, 4])
                )
                .foregroundStyle(Color.ivory.opacity(0.3))
                .padding(32)

            // 四隅コーナーマーク
            viewfinderCorners

            // ライブラベル
            VStack {
                Spacer()
                HStack {
                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.brandPrimary)
                        .kerning(2)
                }
                .padding(.bottom, 16)
            }

            // 中央ガイドテキスト
            Text("顔を枠内に合わせてください")
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.lineColor, lineWidth: 1)
        )
    }

    private var viewfinderCorners: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let arm: CGFloat = 16
            let thick: CGFloat = 1.5

            ZStack {
                // 左上
                Path { p in
                    p.move(to: CGPoint(x: 8, y: 8 + arm))
                    p.addLine(to: CGPoint(x: 8, y: 8))
                    p.addLine(to: CGPoint(x: 8 + arm, y: 8))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                // 右上
                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8))
                    p.addLine(to: CGPoint(x: w - 8, y: 8 + arm))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                // 左下
                Path { p in
                    p.move(to: CGPoint(x: 8, y: h - 8 - arm))
                    p.addLine(to: CGPoint(x: 8, y: h - 8))
                    p.addLine(to: CGPoint(x: 8 + arm, y: h - 8))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)

                // 右下
                Path { p in
                    p.move(to: CGPoint(x: w - 8 - arm, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8))
                    p.addLine(to: CGPoint(x: w - 8, y: h - 8 - arm))
                }
                .stroke(Color.ivory.opacity(0.6), lineWidth: thick)
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if AppEnvironment.useMockImagePicker {
                mockImagePickerButtons
            } else {
                primaryButton
            }
            sampleButton
        }
    }

    private var primaryButton: some View {
        Button {
            viewModel.showImagePicker = true
        } label: {
            HStack(spacing: 8) {
                Text("写真を選ぶ / 撮る")
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
        .aid("advice_photo_picker_button")
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
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.ivory.opacity(0.35), lineWidth: 1)
                )
        }
        .aid("advice_sample_button")
    }

    // モックモード時のボタン群
    private var mockImagePickerButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Button("画像\(index + 1)") {
                        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400))
                        let image = renderer.image { ctx in
                            let hue = CGFloat(index) / 3.0
                            UIColor(hue: hue, saturation: 0.3, brightness: 0.4, alpha: 1).setFill()
                            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
                        }
                        viewModel.selectImage(image, appState: appState)
                    }
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.ivory)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .aid("advice_mock_image_\(index)")
                }
            }

            Text("[MOCK] 画像ピッカー")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.orange.opacity(0.8))
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .aid("advice_mock_image_picker")
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
