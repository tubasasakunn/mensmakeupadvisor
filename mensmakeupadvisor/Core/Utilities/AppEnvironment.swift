import Foundation

enum AppEnvironment {
    static var isMockMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-mode")
    }

    static var useMockImagePicker: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-image-picker")
    }

    static var useMockCamera: Bool {
        ProcessInfo.processInfo.arguments.contains("--mock-camera")
    }
}
