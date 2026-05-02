import SwiftUI

struct ListPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let title = page.title {
                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .foregroundStyle(Color.ivory)
                    .lineSpacing(4)
                    .padding(.bottom, 20)
            }

            if let items = page.listItems {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(items.indices, id: \.self) { i in
                        NumberedListItem(
                            number: String(format: "%02d", i + 1),
                            title: items[i].title,
                            desc: items[i].desc
                        )
                    }
                }
            }
        }
        .padding(.top, 16)
    }
}

struct NumberedListItem: View {
    let number: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Color.brandPrimary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ivory)

                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(4)
            }
        }
    }
}
