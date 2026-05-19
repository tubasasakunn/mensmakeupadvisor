import SwiftUI

// SavedLook の化粧を、直近診断の facemesh の上に実 mesh ID で重ねて表示する。
// 顔写真は持たず Canvas でプログラム描画。Archive のグリッドサムネ用。
struct SavedLookMeshThumbnail: View {
    let look: SavedLook
    // 復元済み細分化メッシュ。HomeArchiveTab が一度ロードして全セルへ渡す。
    var geometry: SavedLookMeshGeometry? = nil

    var body: some View {
        Canvas { ctx, size in
            SavedLookMeshDrawer(context: ctx, size: size, look: look, geometry: geometry).draw()
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

#Preview {
    HStack {
        SavedLookMeshThumbnail(
            look: SavedLook(
                highlight: 40, shadow: 25, eye: 30,
                highlightAreas: ["base_t-zone", "base_c-zone", "base_zintyuu", "base_under-eye"],
                shadowAreas: ["omonaga-lower"],
                eyeAreas: ["eyeshadow_base", "tear_bag", "eyeliner"],
                eyebrowTypeRaw: "natural"
            ),
            geometry: SavedLookMeshGeometry.makeLatest()
        )
        SavedLookMeshThumbnail(
            look: SavedLook(
                highlightAreas: ["marugao_t-zone", "marugao_ago"],
                shadowAreas: ["marugao-side"],
                eyeAreas: ["eyeshadow_crease", "eyeliner"],
                eyebrowTypeRaw: "arch"
            ),
            geometry: SavedLookMeshGeometry.makeLatest()
        )
    }
    .padding()
    .background(Color.appBackground)
}
