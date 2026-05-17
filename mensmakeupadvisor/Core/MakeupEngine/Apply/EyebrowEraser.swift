import CoreGraphics
import Foundation

// 眉ランドマークから dilated polygon mask を生成し、マスク内を上下境界色で
// 線形補間して埋める。OpenCV `inpaint TELEA` の簡易代替。
nonisolated enum EyebrowEraser {
    nonisolated static func erase(image: CGImage, faceMesh: FaceMesh) -> CGImage? {
        let w = image.width
        let h = image.height
        let top = faceMesh.landmark(FaceLandmarkID.foreheadTop, width: w, height: h)
        let chin = faceMesh.landmark(FaceLandmarkID.chinBottom, width: w, height: h)
        let faceH = max(1.0, hypot(top.x - chin.x, top.y - chin.y))
        let expandPx = max(5, Int(Double(faceH) * 0.025))
        let mask = buildPolygonMask(faceMesh: faceMesh, width: w, height: h, expandPx: expandPx)

        // 眉は水平方向に長いので、上下方向の線形補間が自然なフィルになる。
        let count = w * h * 4
        let bytesPerRow = w * 4
        let info: CGBitmapInfo = [
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            CGBitmapInfo.byteOrder32Big,
        ]
        let srcBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        let outBuf = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer { srcBuf.deallocate(); outBuf.deallocate() }
        srcBuf.initialize(repeating: 0, count: count)
        outBuf.initialize(repeating: 0, count: count)

        guard let ctx = CGContext(
            data: srcBuf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue
        ) else { return image }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        for i in 0..<count { outBuf[i] = srcBuf[i] }

        for x in 0..<w {
            var y = 0
            while y < h {
                if mask[x, y] > 0 {
                    let start = y
                    while y < h && mask[x, y] > 0 { y += 1 }
                    let end = y - 1
                    let upY = max(0, start - 1)
                    let dnY = min(h - 1, end + 1)
                    let upIdx = (upY * w + x) * 4
                    let dnIdx = (dnY * w + x) * 4
                    let span = max(1, end - start + 1)
                    for yy in start...end {
                        let t = Double(yy - start + 1) / Double(span + 1)
                        let idx = (yy * w + x) * 4
                        outBuf[idx]     = UInt8(Double(srcBuf[upIdx])     * (1 - t) + Double(srcBuf[dnIdx])     * t)
                        outBuf[idx + 1] = UInt8(Double(srcBuf[upIdx + 1]) * (1 - t) + Double(srcBuf[dnIdx + 1]) * t)
                        outBuf[idx + 2] = UInt8(Double(srcBuf[upIdx + 2]) * (1 - t) + Double(srcBuf[dnIdx + 2]) * t)
                        outBuf[idx + 3] = 255
                    }
                } else {
                    y += 1
                }
            }
        }

        guard let ctx2 = CGContext(
            data: outBuf, width: w, height: h, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue
        ) else { return image }
        return ctx2.makeImage()
    }

    private nonisolated static func buildPolygonMask(faceMesh: FaceMesh, width: Int, height: Int,
                                                     expandPx: Int) -> MaskBuffer {
        let mask = MaskBuffer(width: width, height: height)
        guard let ctx = CGContext(
            data: mask.dataPointer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return mask }
        // landmarksPx は画像座標(Y-DOWN)、CGContext は Y-UP なので flip しないと
        // 消す位置と描く位置がズレる。
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)
        ctx.setFillColor(gray: 1.0, alpha: 1.0)

        let pairs: [(upper: [Int], lower: [Int])] = [
            (FaceLandmarkID.rightEyebrowUpper, FaceLandmarkID.rightEyebrowLower),
            (FaceLandmarkID.leftEyebrowUpper, FaceLandmarkID.leftEyebrowLower),
        ]
        for (upper, lower) in pairs {
            var pts: [CGPoint] = []
            for id in upper where faceMesh.points.indices.contains(id) {
                pts.append(faceMesh.landmark(id, width: width, height: height))
            }
            for id in lower.reversed() where faceMesh.points.indices.contains(id) {
                pts.append(faceMesh.landmark(id, width: width, height: height))
            }
            guard pts.count >= 3 else { continue }
            ctx.beginPath()
            ctx.move(to: pts[0])
            for i in 1..<pts.count { ctx.addLine(to: pts[i]) }
            ctx.closePath()
            ctx.fillPath()
        }

        if expandPx > 0 {
            let f = FloatBuffer.fromMask(mask)
            Morphology.dilate(f, radius: expandPx)
            for i in 0..<mask.count {
                mask.pointer[i] = UInt8(min(255, Int(f.pointer[i] * 255)))
            }
        }
        return mask
    }
}
