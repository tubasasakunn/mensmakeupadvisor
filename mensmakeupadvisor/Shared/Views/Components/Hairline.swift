import SwiftUI

// 1pt のミニマル罫線。アプリ全体で `Rectangle().fill(Color.lineColor).frame(height: 1)`
// を書き散らしていたのを集約する。色とアクティブな塗りも切り出せるので進捗バーにも使える。
struct HairlineDivider: View {
    var color: Color = Color.lineColor
    var height: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
    }
}

// 縦罫線。HStack 内のセパレータ用。
struct HairlineVDivider: View {
    var color: Color = Color.lineColor
    var width: CGFloat = 1
    var height: CGFloat? = nil

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: height)
    }
}

#Preview {
    ZStack {
        Color.appBackground.ignoresSafeArea()
        VStack(spacing: 24) {
            HairlineDivider()
            HairlineDivider(color: Color.brandPrimary, height: 2)
            HStack {
                Text("A")
                HairlineVDivider(height: 24)
                Text("B")
            }
            .foregroundStyle(Color.ivory)
        }
        .padding(40)
    }
}
