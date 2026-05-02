import SwiftData
import SwiftUI

// 320×400 = 4:5 ルックシェアカード (scale×3 → 960×1200px)
struct LookShareCardView: View {
    let look: SavedLook

    var body: some View {
        ZStack {
            Color.appBackground

            VStack(alignment: .leading, spacing: 0) {
                topBar
                    .padding(.top, 28)
                    .padding(.horizontal, 28)

                lookPreview
                    .padding(.top, 18)
                    .padding(.horizontal, 28)

                lookInfo
                    .padding(.top, 14)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
            }
        }
        .frame(width: 320, height: 400)
    }

    // MARK: - Subviews

    private var topBar: some View {
        HStack {
            Text("M · M · A")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.brandPrimary)
                .kerning(2)
            Spacer()
            Text("MY LOOK")
                .font(.system(size: 9, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.inkSecondary)
                .kerning(2)
        }
    }

    private var lookPreview: some View {
        ZStack {
            Color(red: 0.12, green: 0.10, blue: 0.08)

            LinearGradient(
                colors: [Color.ivory.opacity(opacityFor(look.highlight, scale: 80)), Color.clear],
                startPoint: .top, endPoint: .center
            )

            RadialGradient(
                colors: [
                    Color(red: 0.75, green: 0.60, blue: 0.48).opacity(opacityFor(look.base, scale: 80)),
                    Color.clear
                ],
                center: .center, startRadius: 0, endRadius: 80
            )

            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.clear],
                startPoint: .bottom, endPoint: .init(x: 0.5, y: 0.55)
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("SCORE \(look.totalScore)")
                        .font(.system(size: 10, weight: .light, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory.opacity(0.6))
                        .padding(10)
                }
            }
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    private func opacityFor(_ value: Double, scale: Double) -> Double {
        let n = min(max(value / scale, 0), 1)
        return 0.08 + n * 0.47
    }

    private var lookInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle().fill(Color.lineColor).frame(height: 1)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(presetLabel)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .italic()
                        .foregroundStyle(Color.ivory)

                    Text(look.createdAt, format: .dateTime.year().month().day())
                        .font(.system(size: 9, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.inkSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text("MensMakeupAdvisor")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.ivory.opacity(0.3))
                        .kerning(1)
                    Text("このルックを試す")
                        .font(.system(size: 7, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.inkTertiary)
                }
            }
        }
    }

    private var presetLabel: String {
        guard let pid = look.presetID,
              let preset = MakeupPreset.all.first(where: { $0.id == pid })
        else { return "CUSTOM" }
        return preset.label.uppercased()
    }
}

#Preview {
    LookShareCardView(
        look: SavedLook(
            id: "preview-1",
            createdAt: .now,
            presetID: "k-style",
            totalScore: 82,
            faceShape: "tamago",
            base: 35, highlight: 40, shadow: 28, eye: 42, eyebrow: 55
        )
    )
    .modelContainer(for: [SavedLook.self], inMemory: true)
}
