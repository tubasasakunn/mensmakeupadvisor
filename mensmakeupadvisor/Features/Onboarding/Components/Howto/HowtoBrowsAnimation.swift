import SwiftUI

struct HowtoBrowsAnimation: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = HowtoLoop.progress(ctx.date)
            // ワイプの進行（0..1）— 0->10% 待機、10->40% で 0->1、40->60% キープ、60->90% で 1->0、90->100% 待機
            let wipe = HowtoKeyframes.value(at: t, stops: [
                (0.00, 0), (0.10, 0), (0.40, 1), (0.60, 1), (0.90, 0), (1.00, 0)
            ])

            ZStack {
                Image("howto_face_plain")
                    .resizable()
                    .scaledToFit()

                Image("howto_face_brows")
                    .resizable()
                    .scaledToFit()
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle()
                                .frame(width: geo.size.width * wipe)
                        }
                    }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HowtoBrowsAnimation()
        .frame(width: 260, height: 260)
        .background(Color.gray.opacity(0.1))
}
