import SwiftUI

struct ConceptPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let ct = page.conceptTitle {
                Text(ct)
                    .font(.system(size: 60, weight: .light, design: .serif))
                    .italic()
                    .foregroundStyle(Color.ivory)
                    .padding(.bottom, 4)
            }

            if let jp = page.titleJP {
                Text(jp)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.brandPrimary)
                    .kerning(2)
                    .padding(.bottom, 20)
            }

            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
                .padding(.bottom, 16)

            if let body = page.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.inkSecondary)
                    .lineSpacing(8)
                    .padding(.bottom, 12)
            }

            if let source = page.source {
                Text(source)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(Color.inkSecondary.opacity(0.6))
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 16)
    }
}
