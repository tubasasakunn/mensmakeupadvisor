import SwiftUI

// 検出した顔の上に「塗る位置」を半透明ゾーンで重ねるオーバーレイ。
//
// 現行 MakeupRenderer は静止画前提 (非同期・デバウンス) で 30fps の写実合成には
// 向かないため、ミラーモードでは写実合成ではなく "どこに入れるか" のガイドを描く。
// ハイライト = sulphur、シェーディング = bordeaux で色分けする。
//
// 座標について:
//   FaceObservation は Vision 正規化座標 (原点 左下)。ここで View 座標 (原点 左上)
//   へ変換する。プレビューは aspect-fill かつフロントは鏡像表示のため厳密な一致は
//   実機での微調整前提 (mirrorX / aspect 補正)。目・鼻はランドマークに、額・あご・頬は
//   bounding box の比率に追従させ、多少の座標ズレに強い作りにしている。
struct MirrorGuideOverlay: View {
    let face: FaceObservation?

    // 実機で左右が反転して見える場合に切り替える調整点。
    // (.leftMirrored 検出 + 鏡像プレビューの組み合わせを既定で想定し false)
    private let mirrorX = false

    var body: some View {
        Canvas { context, size in
            guard let face, face.hasFace else { return }
            let box = viewBox(face.boundingBox, in: size)
            let eyeL = face.leftEyeCenter.map { viewPoint($0, in: size) }
            let eyeR = face.rightEyeCenter.map { viewPoint($0, in: size) }
            let nose = face.noseCenter.map { viewPoint($0, in: size) }

            for zone in shadowZones(box: box) {
                let path = Path(ellipseIn: zone)
                context.fill(path, with: .color(Theme.Accent.primary.opacity(0.20)))
                context.stroke(path, with: .color(Theme.Accent.primary.opacity(0.55)), lineWidth: 1)
            }
            for zone in highlightZones(box: box, eyeL: eyeL, eyeR: eyeR, nose: nose) {
                let path = Path(ellipseIn: zone)
                context.fill(path, with: .color(Color.sulphur.opacity(0.20)))
                context.stroke(path, with: .color(Color.sulphur.opacity(0.65)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .aid("mirror_guide_overlay")
    }

    // ハイライト: 額・鼻筋・目の下・あご先。目の下と鼻筋は検出座標に追従させ、
    // 取得できなければ box 比率にフォールバックする。
    private func highlightZones(box: CGRect, eyeL: CGPoint?, eyeR: CGPoint?, nose: CGPoint?) -> [CGRect] {
        let w = box.width, h = box.height, x = box.minX, y = box.minY
        var zones: [CGRect] = [
            CGRect(x: x + w * 0.24, y: y + h * 0.05, width: w * 0.52, height: h * 0.12), // 額
            CGRect(x: box.midX - w * 0.11, y: y + h * 0.86, width: w * 0.22, height: h * 0.10), // あご先
        ]

        // 鼻筋: 目の中間 → 鼻先。座標があれば結ぶ、無ければ box 中央。
        let bridgeTop = midpoint(eyeL, eyeR) ?? CGPoint(x: box.midX, y: y + h * 0.32)
        let bridgeBottom = nose ?? CGPoint(x: box.midX, y: y + h * 0.58)
        zones.append(capsuleRect(from: bridgeTop, to: bridgeBottom, thickness: w * 0.10))

        // 目の下ハイライト。
        let underEyeSize = CGSize(width: w * 0.22, height: h * 0.09)
        if let eyeL {
            zones.append(centeredRect(at: CGPoint(x: eyeL.x, y: eyeL.y + h * 0.10), size: underEyeSize))
        } else {
            zones.append(CGRect(x: x + w * 0.16, y: y + h * 0.44, width: underEyeSize.width, height: underEyeSize.height))
        }
        if let eyeR {
            zones.append(centeredRect(at: CGPoint(x: eyeR.x, y: eyeR.y + h * 0.10), size: underEyeSize))
        } else {
            zones.append(CGRect(x: x + w * 0.62, y: y + h * 0.44, width: underEyeSize.width, height: underEyeSize.height))
        }
        return zones
    }

    // シェーディング: 両サイドとエラ。box 比率で配置。
    private func shadowZones(box: CGRect) -> [CGRect] {
        let w = box.width, h = box.height, x = box.minX, y = box.minY
        return [
            CGRect(x: x - w * 0.02, y: y + h * 0.42, width: w * 0.16, height: h * 0.30), // 左サイド
            CGRect(x: x + w * 0.86, y: y + h * 0.42, width: w * 0.16, height: h * 0.30), // 右サイド
            CGRect(x: box.midX - w * 0.22, y: y + h * 0.78, width: w * 0.16, height: h * 0.10), // 左エラ
            CGRect(x: box.midX + w * 0.06, y: y + h * 0.78, width: w * 0.16, height: h * 0.10), // 右エラ
        ]
    }

    // MARK: - Coordinate helpers

    private func viewPoint(_ p: CGPoint, in size: CGSize) -> CGPoint {
        let vx = (mirrorX ? (1 - p.x) : p.x) * size.width
        let vy = (1 - p.y) * size.height   // Vision 左下原点 → View 左上原点
        return CGPoint(x: vx, y: vy)
    }

    private func viewBox(_ bb: CGRect, in size: CGSize) -> CGRect {
        let a = viewPoint(CGPoint(x: bb.minX, y: bb.maxY), in: size)   // 左上
        let b = viewPoint(CGPoint(x: bb.maxX, y: bb.minY), in: size)   // 右下
        return CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }

    private func midpoint(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
        guard let a, let b else { return nil }
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func centeredRect(at center: CGPoint, size: CGSize) -> CGRect {
        CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    private func capsuleRect(from top: CGPoint, to bottom: CGPoint, thickness: CGFloat) -> CGRect {
        let minY = min(top.y, bottom.y)
        let maxY = max(top.y, bottom.y)
        let cx = (top.x + bottom.x) / 2
        return CGRect(x: cx - thickness / 2, y: minY, width: thickness, height: max(maxY - minY, thickness))
    }
}

#Preview {
    ZStack {
        Color.black
        MirrorGuideOverlay(
            face: FaceObservation(boundingBox: CGRect(x: 0.28, y: 0.25, width: 0.44, height: 0.5))
        )
    }
    .ignoresSafeArea()
}
