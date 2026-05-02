import SwiftUI

struct ExamplePageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 20)
            }

            if let items = page.exampleItems {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(items.indices, id: \.self) { i in
                        ExampleItemView(
                            concern: items[i].concern,
                            advice: items[i].advice
                        )
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

struct ExampleItemView: View {
    let concern: String
    let advice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text("Q")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary)
                    .padding(.top, 2)
                Text(concern)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(3)
            }

            HStack(alignment: .top, spacing: 8) {
                Text("→")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.top, 2)
                Text(advice)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(14)
        .background(Color.ivory.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.lineColor, lineWidth: 1)
        )
    }
}
