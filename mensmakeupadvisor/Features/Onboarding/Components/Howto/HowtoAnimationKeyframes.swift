import Foundation
import SwiftUI

// CSS @keyframes 相当: ソート済み (進捗0-1, 値) ストップ間を補間する
enum HowtoKeyframes {
    static func value(
        at t: Double,
        stops: [(Double, Double)],
        ease: (Double) -> Double = HowtoEasing.easeInOut
    ) -> Double {
        guard let first = stops.first, let last = stops.last else { return 0 }
        if t <= first.0 { return first.1 }
        if t >= last.0 { return last.1 }
        for i in 0..<stops.count - 1 {
            let a = stops[i], b = stops[i + 1]
            if t >= a.0 && t <= b.0 {
                if a.0 == b.0 { return b.1 }
                let p = (t - a.0) / (b.0 - a.0)
                return a.1 + (b.1 - a.1) * ease(p)
            }
        }
        return last.1
    }
}

enum HowtoEasing {
    static func easeInOut(_ x: Double) -> Double { -(cos(.pi * x) - 1) / 2 }
    static func linear(_ x: Double) -> Double { x }
}

// SVG の 500x500 ローカル座標で描いたコンテンツを親フレームにフィットさせる
struct HowtoScaledOverlay<Content: View>: View {
    var originalSize: CGFloat = 500
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width, geo.size.height) / originalSize
            content()
                .frame(width: originalSize, height: originalSize, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }
}

// 6 秒ループの進捗 0..1 を返す
enum HowtoLoop {
    static let duration: Double = 6
    static func progress(_ date: Date) -> Double {
        let secs = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration)
        return secs / duration
    }
}
