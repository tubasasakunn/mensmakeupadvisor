import Foundation

// makeup_claude の Python 実装で扱っていたグレースケール/単一チャンネル画素バッファ
// を Swift で表現するための薄い container。Accelerate / vDSP に渡せる
// UnsafeMutablePointer をそのまま保持する。

nonisolated final class MaskBuffer {
    let width: Int
    let height: Int
    nonisolated(unsafe) private let basePointer: UnsafeMutablePointer<UInt8>

    nonisolated init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let totalCount = width * height
        let raw = UnsafeMutableRawPointer.allocate(byteCount: totalCount, alignment: 16)
        raw.initializeMemory(as: UInt8.self, repeating: 0, count: totalCount)
        self.basePointer = raw.assumingMemoryBound(to: UInt8.self)
    }

    deinit {
        UnsafeMutableRawPointer(basePointer).deallocate()
    }

    nonisolated var dataPointer: UnsafeMutableRawPointer { UnsafeMutableRawPointer(basePointer) }
    nonisolated var pointer: UnsafeMutablePointer<UInt8> { basePointer }
    nonisolated var count: Int { width * height }

    nonisolated subscript(x: Int, y: Int) -> UInt8 {
        get { basePointer[y * width + x] }
        set { basePointer[y * width + x] = newValue }
    }
}

nonisolated final class FloatBuffer {
    let width: Int
    let height: Int
    nonisolated(unsafe) private let basePointer: UnsafeMutablePointer<Float>

    nonisolated init(width: Int, height: Int) {
        self.width = width
        self.height = height
        let totalCount = width * height
        let raw = UnsafeMutableRawPointer.allocate(
            byteCount: totalCount * MemoryLayout<Float>.stride,
            alignment: 16
        )
        raw.initializeMemory(as: Float.self, repeating: 0, count: totalCount)
        self.basePointer = raw.assumingMemoryBound(to: Float.self)
    }

    deinit {
        UnsafeMutableRawPointer(basePointer).deallocate()
    }

    nonisolated var pointer: UnsafeMutablePointer<Float> { basePointer }
    nonisolated var count: Int { width * height }

    nonisolated subscript(x: Int, y: Int) -> Float {
        get { basePointer[y * width + x] }
        set { basePointer[y * width + x] = newValue }
    }

    nonisolated static func fromMask(_ mask: MaskBuffer) -> FloatBuffer {
        let out = FloatBuffer(width: mask.width, height: mask.height)
        for i in 0..<out.count {
            out.pointer[i] = Float(mask.pointer[i]) / 255.0
        }
        return out
    }
}
