import SwiftUI
import UIKit

struct PrinciplePageView: View {
    let page: OnboardingPage

    // tag から画像を探す: "MISTAKE 01" → "mistake_01"
    private var illustrationImage: UIImage? {
        let key = page.tag.lowercased().replacingOccurrences(of: " ", with: "_")
        return UIImage(named: key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let num = page.num {
                Text(num)
                    .font(Theme.Typography.Display.colossalLBold)
                    .italic()
                    .foregroundStyle(Theme.Accent.primarySoft)
                    .padding(.bottom, -8)
            }

            if let title = page.title {
                Text(title)
                    .font(Theme.Typography.Display.titleLBold)
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 12)
            }

            if let body = page.body {
                Text(body)
                    .font(Theme.Typography.UI.body)
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(5)
                    .padding(.bottom, illustrationImage != nil ? 14 : 20)
            }

            if let img = illustrationImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 16)
            }

            if let items = page.items {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items.indices, id: \.self) { i in
                        PrincipleItemRow(title: items[i].title, desc: items[i].desc)
                    }
                }
                .padding(.bottom, 12)
            }

            if let footer = page.footer {
                HairlineDivider()
                    .padding(.bottom, 10)

                Text(footer)
                    .font(Theme.Typography.UI.footnote)
                    .foregroundStyle(Theme.Text.secondaryFaded)
                    .lineSpacing(4)
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}

struct PrincipleItemRow: View {
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(Theme.Typography.UI.subheadlineSemibold)
                .foregroundStyle(Color.ivory)

            Text(desc)
                .font(Theme.Typography.UI.subheadline)
                .foregroundStyle(Color.inkSecondary)
                .lineSpacing(4)
        }
        .padding(.leading, 12)
        .overlay(
            Rectangle()
                .fill(Theme.Plate.scanLineGlow)
                .frame(width: 2),
            alignment: .leading
        )
    }
}
