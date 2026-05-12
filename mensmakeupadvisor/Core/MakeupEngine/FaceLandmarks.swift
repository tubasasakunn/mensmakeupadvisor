import Foundation

// MediaPipe FaceLandmarker (478点) のランドマークID定数。
// makeup_claude/loadmap/shared/face_metrics.py の `LM` クラスをそのまま移植している。
nonisolated enum FaceLandmarkID {
    // MARK: - 縦軸
    nonisolated static let foreheadTop = 10
    nonisolated static let chinBottom = 152
    nonisolated static let glabella = 9       // 眉間
    nonisolated static let noseRoot = 168     // 鼻根
    nonisolated static let noseTip = 1
    nonisolated static let subnasal = 2

    // MARK: - 横軸
    nonisolated static let templeR = 234
    nonisolated static let templeL = 454
    nonisolated static let cheekboneR = 127
    nonisolated static let cheekboneL = 356
    nonisolated static let gonionR = 172      // 下顎角(エラ)
    nonisolated static let gonionL = 397
    nonisolated static let jawR = 132
    nonisolated static let jawL = 361
    nonisolated static let lowerJawR = 136
    nonisolated static let lowerJawL = 365
    nonisolated static let foreheadR = 54
    nonisolated static let foreheadL = 284

    // MARK: - 目
    nonisolated static let eyeOuterR = 33
    nonisolated static let eyeInnerR = 133
    nonisolated static let eyeInnerL = 362
    nonisolated static let eyeOuterL = 263
    nonisolated static let eyeTopR = 159
    nonisolated static let eyeBotR = 145
    nonisolated static let eyeTopL = 386
    nonisolated static let eyeBotL = 374
    nonisolated static let irisR: [Int] = [468, 469, 470, 471, 472]
    nonisolated static let irisL: [Int] = [473, 474, 475, 476, 477]

    // MARK: - 鼻
    nonisolated static let noseWingR = 64
    nonisolated static let noseWingL = 294
    nonisolated static let noseWingROut = 129
    nonisolated static let noseWingLOut = 358

    // MARK: - 口
    nonisolated static let mouthR = 61
    nonisolated static let mouthL = 291
    nonisolated static let upperLipTop = 0
    nonisolated static let upperLipIn = 13
    nonisolated static let lowerLipIn = 14
    nonisolated static let lowerLipBot = 17

    // MARK: - 眉
    nonisolated static let browHeadR = 55
    nonisolated static let browHeadL = 285
    nonisolated static let browTailR = 46
    nonisolated static let browTailL = 276
    nonisolated static let browPeakR = 105
    nonisolated static let browPeakL = 334

    // MARK: - 眉領域ポリゴン（眉消し用）
    nonisolated static let rightEyebrowUpper: [Int] = [70, 63, 105, 66, 107]
    nonisolated static let rightEyebrowLower: [Int] = [46, 53, 52, 65, 55]
    nonisolated static let leftEyebrowUpper: [Int] = [300, 293, 334, 296, 336]
    nonisolated static let leftEyebrowLower: [Int] = [276, 283, 282, 295, 285]
}
