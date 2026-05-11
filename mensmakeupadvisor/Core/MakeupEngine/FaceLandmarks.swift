import Foundation

// MediaPipe FaceLandmarker (478点) のランドマークID定数。
// makeup_claude/loadmap/shared/face_metrics.py の `LM` クラスをそのまま移植している。
enum FaceLandmarkID {
    // MARK: - 縦軸
    static let foreheadTop = 10
    static let chinBottom = 152
    static let glabella = 9       // 眉間
    static let noseRoot = 168     // 鼻根
    static let noseTip = 1
    static let subnasal = 2

    // MARK: - 横軸
    static let templeR = 234
    static let templeL = 454
    static let cheekboneR = 127
    static let cheekboneL = 356
    static let gonionR = 172      // 下顎角(エラ)
    static let gonionL = 397
    static let jawR = 132
    static let jawL = 361
    static let lowerJawR = 136
    static let lowerJawL = 365
    static let foreheadR = 54
    static let foreheadL = 284

    // MARK: - 目
    static let eyeOuterR = 33
    static let eyeInnerR = 133
    static let eyeInnerL = 362
    static let eyeOuterL = 263
    static let eyeTopR = 159
    static let eyeBotR = 145
    static let eyeTopL = 386
    static let eyeBotL = 374
    static let irisR: [Int] = [468, 469, 470, 471, 472]
    static let irisL: [Int] = [473, 474, 475, 476, 477]

    // MARK: - 鼻
    static let noseWingR = 64
    static let noseWingL = 294
    static let noseWingROut = 129
    static let noseWingLOut = 358

    // MARK: - 口
    static let mouthR = 61
    static let mouthL = 291
    static let upperLipTop = 0
    static let upperLipIn = 13
    static let lowerLipIn = 14
    static let lowerLipBot = 17

    // MARK: - 眉
    static let browHeadR = 55
    static let browHeadL = 285
    static let browTailR = 46
    static let browTailL = 276
    static let browPeakR = 105
    static let browPeakL = 334

    // MARK: - 眉領域ポリゴン（眉消し用）
    static let rightEyebrowUpper: [Int] = [70, 63, 105, 66, 107]
    static let rightEyebrowLower: [Int] = [46, 53, 52, 65, 55]
    static let leftEyebrowUpper: [Int] = [300, 293, 334, 296, 336]
    static let leftEyebrowLower: [Int] = [276, 283, 282, 295, 285]
}
