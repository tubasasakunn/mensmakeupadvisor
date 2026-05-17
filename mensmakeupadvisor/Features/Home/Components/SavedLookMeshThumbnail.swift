import SwiftUI

// SavedLook がどの部位に化粧を入れたかを、汎用的な顔ダイアグラム上に
// ハイライト/シェード/アイ/眉の色で塗り分けて表示する。
// 実画像は持たないので Canvas でプログラム描画。Archive のグリッドサムネ用。
struct SavedLookMeshThumbnail: View {
    let look: SavedLook

    var body: some View {
        Canvas { ctx, size in
            let drawer = SavedLookMeshDrawer(context: ctx, size: size, look: look)
            drawer.draw()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack {
        SavedLookMeshThumbnail(look: SavedLook(
            highlight: 40, shadow: 25, eye: 30,
            highlightAreas: ["base_t-zone", "base_c-zone", "base_zintyuu", "base_under-eye"],
            shadowAreas: ["omonaga-lower"],
            eyeAreas: ["eyeshadow_base", "tear_bag", "eyeliner"],
            eyebrowTypeRaw: "natural"
        ))
        SavedLookMeshThumbnail(look: SavedLook(
            highlightAreas: ["marugao_t-zone", "marugao_ago"],
            shadowAreas: ["marugao-side"],
            eyeAreas: ["eyeshadow_crease", "eyeliner"],
            eyebrowTypeRaw: "arch"
        ))
    }
    .padding()
    .background(Color.appBackground)
}
