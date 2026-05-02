import SwiftUI

struct OnboardPageContentView: View {
    let page: OnboardingPage

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                pageContent
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: geo.size.height, alignment: .top)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
            }
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        switch page.kind {
        case .cover:     CoverPageView(page: page)
        case .stat:      StatPageView(page: page)
        case .compare:   ComparePageView(page: page)
        case .concept:   ConceptPageView(page: page)
        case .thesis:    ThesisPageView(page: page)
        case .principle: PrinciplePageView(page: page)
        case .duo:       DuoPageView(page: page)
        case .example:   ExamplePageView(page: page)
        case .goal:      GoalPageView(page: page)
        case .list:      ListPageView(page: page)
        case .feature:   FeaturePageView(page: page)
        case .howto:     HowtoPageView(page: page)
        case .cta:       CtaPageView(page: page)
        }
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        OnboardPageContentView(page: OnboardingPage.all[0])
    }
}
