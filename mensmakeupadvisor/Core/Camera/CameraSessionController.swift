import AVFoundation
import CoreVideo
import SwiftUI

// ミラーモードのフロントカメラ・セッションを統括する。
//
// 設計 (Swift 6 strict concurrency):
//   - AVCaptureSession / Input / Output は Sendable ではないため、全て本クラス
//     (@MainActor) の隔離内だけで生成・操作し、他ドメインへ渡さない。
//     プレビュー層 (CameraPreviewView) も MainActor なので session 参照の共有は安全。
//   - フレーム検出は CameraFrameProcessor が別キューで行い、結果は Sendable な
//     FaceObservation として AsyncStream 経由でここへ届く。
//   - startRunning() は MainActor で呼ぶ (セッション開始時に一瞬ブロックし得るが、
//     MVP では許容。気になる場合は専用キューへ退避する余地を残す)。
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
    private(set) var face: FaceObservation?

    let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let processor = CameraFrameProcessor()
    private let processingQueue = DispatchQueue(label: "mirror.camera.frames", qos: .userInitiated)
    private var consumeTask: Task<Void, Never>?

    func start() async {
        guard status != .running, status != .configuring else { return }

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
        face = nil
        status = .idle
    }

    private func configureIfNeeded() throws {
        // 二度目以降の start では既に input/output が組まれているので再構成しない。
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high

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
        // stream (Sendable) だけを捕捉し self は弱参照。stop() の cancel で
        // await が解け、コントローラを retain したまま固まらないようにする。
        let stream = processor.stream
        consumeTask = Task { [weak self] in
            for await observation in stream {
                guard let self, !Task.isCancelled else { break }
                self.face = observation
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
