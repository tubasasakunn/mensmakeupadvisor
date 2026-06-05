import AVFoundation
import CoreVideo
import SwiftUI

// ミラーモードのフロントカメラ・セッションを統括し、各フレームに化粧を合成して
// renderedFrame に出力する。
//
// 設計 (Swift 6 strict concurrency):
//   - AVCaptureSession / Input / Output は Sendable ではないため、全て本クラス
//     (@MainActor) の隔離内だけで生成・操作する。
//   - フレーム変換は CameraFrameProcessor が別キューで行い、Sendable な UIImage を
//     AsyncStream で届ける。合成は LiveMirrorRenderer (actor) 上で実行され、
//     その await 中は MainActor がブロックされない。
//   - スロットリング: 合成中は for-await が中断し、bufferingNewest(1) が中間
//     フレームを捨てるため、自然に「合成レート」までフレームが間引かれる。
@Observable
@MainActor
final class CameraSessionController {
    enum Status: Equatable {
        case idle
        case configuring
        case running
        case denied
        case failed(String)
    }

    private(set) var status: Status = .idle
    // 直近に化粧合成できたフレーム。検出失敗フレームでは更新せず前回を保持する。
    private(set) var renderedFrame: UIImage?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processor = CameraFrameProcessor()
    private let renderer = LiveMirrorRenderer()
    private let processingQueue = DispatchQueue(label: "mirror.camera.frames", qos: .userInitiated)
    private var consumeTask: Task<Void, Never>?
    private var composition: MakeupComposition = .empty

    func start(composition: MakeupComposition) async {
        guard status != .running, status != .configuring else { return }
        self.composition = composition

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            guard granted else { status = .denied; return }
        default:
            status = .denied
            return
        }

        status = .configuring
        do {
            try configureIfNeeded()
        } catch {
            status = .failed(error.localizedDescription)
            return
        }

        consume()
        session.startRunning()
        status = .running
    }

    func stop() {
        consumeTask?.cancel()
        consumeTask = nil
        if session.isRunning { session.stopRunning() }
        // ストリームを閉じる。本コントローラは画面遷移ごとに作り直されるため
        // (MirrorView の @State) 再開での使い回しはなく、ここで終端して問題ない。
        processor.finish()
        renderedFrame = nil
        status = .idle
    }

    private func configureIfNeeded() throws {
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        // ライブ合成の負荷を抑えるため 720p に固定 (実機で重ければ要調整)。
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw CameraError.noFrontCamera
        }
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CameraError.cannotConfigure }
        session.addInput(input)

        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(processor, queue: processingQueue)
        guard session.canAddOutput(videoOutput) else { throw CameraError.cannotConfigure }
        session.addOutput(videoOutput)
    }

    private func consume() {
        // 全て Sendable (stream / renderer / composition) を捕捉し self は弱参照。
        let stream = processor.stream
        let renderer = self.renderer
        let composition = self.composition
        consumeTask = Task { [weak self] in
            for await frame in stream {
                if Task.isCancelled { break }
                // 重い合成は actor 上で実行 (MainActor を止めない)。await 中は
                // 次フレームの取得が止まり、古いフレームは自然に捨てられる。
                let rendered = await renderer.renderMakeup(on: frame, composition: composition)
                guard let self, !Task.isCancelled else { break }
                if let rendered { self.renderedFrame = rendered }
            }
        }
    }

    enum CameraError: LocalizedError {
        case noFrontCamera
        case cannotConfigure

        var errorDescription: String? {
            switch self {
            case .noFrontCamera: "フロントカメラが見つかりませんでした"
            case .cannotConfigure: "カメラの初期化に失敗しました"
            }
        }
    }
}
