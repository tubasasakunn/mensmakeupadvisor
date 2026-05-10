import SwiftUI

struct HowtoPageView: View {
    let page: OnboardingPage

    // step名に対応するイラスト asset 名: howto_base / howto_highlight / howto_shadow / howto_eyes / howto_brows
    private var illustrationAssetName: String? {
        guard let step = page.step else { return nil }
        let name = "howto_\(step.lowercased())"
        // asset が存在するか確認（UIImage で存在チェック）
        return UIImage(named: name) != nil ? name : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let step = page.step {
                Text(step)
                    .font(.system(size: 120, weight: .bold, design: .serif))
                    .italic()
                    .foregroundStyle(Color.brandPrimary.opacity(0.28))
                    .padding(.bottom, -30)
            }

            if let title = page.title {
                Text(title)
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 14)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let assetName = illustrationAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 180)
                    .padding(.bottom, 16)
            }

            if let body = page.body {
                Text(body)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(7)
            }
        }
        .padding(.top, 8)
    }
}
