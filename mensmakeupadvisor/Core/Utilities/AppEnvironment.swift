import Foundation

enum AppEnvironment {
    static var isMockMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-mode")
    }

    static var useMockImagePicker: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-image-picker")
    }

    static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--screenshot-mode")
    }

    // ミラーモードのライブカメラを差し替える。シミュレータ/Maestro では
    // 実カメラが無いので、--mock-mode 時はカメラ初期化を避け静的プレースホルダを出す。
    static var useMockCamera: Bool {
        isMockMode || ProcessInfo.processInfo.arguments.contains("--mock-camera")
    }

    // 初回起動でホーム画面まで到達したか。Splash 後の遷移分岐に使う。
    // 一度立てたら以降は Splash → Home に直行し、Onboarding を読み直すのは
    // ユーザーが明示的に望んだ時だけ（現状はその導線なし）。
    private static let didReachHomeKey = "didReachHomeOnce"

    static var didReachHomeOnce: Bool {
        get { UserDefaults.standard.bool(forKey: didReachHomeKey) }
        set { UserDefaults.standard.set(newValue, forKey: didReachHomeKey) }
    }
}
