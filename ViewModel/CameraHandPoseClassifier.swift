import AVFoundation
import Combine
import CoreImage
import CoreML
import UIKit
import Vision

struct CameraHandPoseState {
    var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    var cameraErrorMessage: String?
    var countdownRemaining: Int?
    var frozenFrameImage: UIImage?
    var recognizedMove: HandMove?
    var isRoundFrozen = false
    var isRoundActive = false
}

final class CameraHandPoseClassifier: NSObject {
    @Published private(set) var state = CameraHandPoseState()

    let session = AVCaptureSession()

    private let sessionQueue = DispatchQueue(label: "rcsw.camera.session")
    private let videoOutputQueue = DispatchQueue(label: "rcsw.camera.video-output")
    private let handPoseRequest = VNDetectHumanHandPoseRequest()
    private let ciContext = CIContext()
    private let roundDuration: TimeInterval = 3

    private var classifierModel: RockPaperScissorClassifier?
    private var roundState = RoundStateMachine()
    private var shouldBeginRoundWhenAuthorized = false
    private var isSessionConfigured = false
    private var isProcessingFrame = false

    var authorizationStatus: AVAuthorizationStatus {
        state.authorizationStatus
    }

    var recognizedMove: HandMove? {
        state.recognizedMove
    }

    var countdownRemaining: Int? {
        state.countdownRemaining
    }

    var isRoundFrozen: Bool {
        state.isRoundFrozen
    }

    override init() {
        super.init()

        handPoseRequest.maximumHandCount = 1

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        classifierModel = try? RockPaperScissorClassifier(configuration: configuration)

        if classifierModel == nil {
            state.cameraErrorMessage = "Unable to load the hand gesture classifier."
        }
    }

    func requestCameraAccessIfNeeded() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        updateState { state in
            state.authorizationStatus = currentStatus
        }

        switch currentStatus {
        case .authorized:
            startSession()
            if shouldBeginRoundWhenAuthorized {
                beginRound()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                self?.updateState { state in
                    state.authorizationStatus = granted ? .authorized : .denied
                }

                if granted {
                    self?.startSession()
                    if self?.shouldBeginRoundWhenAuthorized == true {
                        DispatchQueue.main.async {
                            self?.beginRound()
                        }
                    }
                } else {
                    self?.updateCameraError("Enable camera access in Settings to recognize your move.")
                }
            }
        case .denied, .restricted:
            updateCameraError("Enable camera access in Settings to recognize your move.")
        @unknown default:
            updateCameraError("Camera permission is unavailable.")
        }
    }

    func beginRound() {
        switch authorizationStatus {
        case .authorized:
            shouldBeginRoundWhenAuthorized = false
            resetRoundState()
            startSession()
        case .notDetermined:
            shouldBeginRoundWhenAuthorized = true
            requestCameraAccessIfNeeded()
        case .denied, .restricted:
            updateCameraError("Enable camera access in Settings to recognize your move.")
        @unknown default:
            updateCameraError("Camera permission is unavailable.")
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isSessionConfigured {
                self.configureSession()
            }

            guard self.isSessionConfigured, !self.session.isRunning else { return }
            print("Session Start running....")
            self.session.startRunning()
        }
    }

    private func configureSession() {
        guard !isSessionConfigured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high
        defer { session.commitConfiguration() }

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            updateCameraError("Front camera is unavailable on this device.")
            return
        }

        do {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(cameraInput) else {
                updateCameraError("Unable to add the front camera input.")
                return
            }
            session.addInput(cameraInput)
        } catch {
            updateCameraError("Unable to open the front camera.")
            return
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)

        guard session.canAddOutput(videoOutput) else {
            updateCameraError("Unable to read frames from the front camera.")
            return
        }

        session.addOutput(videoOutput)

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }

        isSessionConfigured = true
        updateCameraError(nil)
    }

    private func resetRoundState() {
        videoOutputQueue.async {
            self.roundState.beginRound()
            self.isProcessingFrame = false
        }

        updateState { state in
            state.countdownRemaining = nil
            state.recognizedMove = nil
            state.frozenFrameImage = nil
            state.isRoundFrozen = false
            state.isRoundActive = true
        }
    }

    private func predictMove(in pixelBuffer: CVPixelBuffer) -> HandMove? {
        guard let classifierModel else { return nil }

        do {
            let handler = VNImageRequestHandler(
                cvPixelBuffer: pixelBuffer,
                orientation: .leftMirrored,
                options: [:]
            )
            try handler.perform([handPoseRequest])

            guard let observation = handPoseRequest.results?.first else {
                return nil
            }

            let pose = try observation.keypointsMultiArray()
            let prediction = try classifierModel.prediction(input: RockPaperScissorClassifierInput(poses: pose))
            let confidence = prediction.labelProbabilities[prediction.label] ?? 0

            guard confidence >= 0.60, let move = HandMove(modelLabel: prediction.label) else {
                return nil
            }

            return move
        } catch {
            return nil
        }
    }

    private func startCountdown(at now: Date) {
        guard roundState.registerDetectedGesture(at: now, freezeAfter: roundDuration) != nil else {
            return
        }

        updateState { state in
            state.countdownRemaining = self.roundState.countdownRemaining(at: now)
        }
    }

    private func freezeRound(using pixelBuffer: CVPixelBuffer) {
        let frozenFrameImage = makeFrozenFrameImage(from: pixelBuffer)
        let recognizedMove = predictMove(in: pixelBuffer)

        stopSession()

        updateState { state in
            state.countdownRemaining = nil
            state.recognizedMove = recognizedMove
            state.frozenFrameImage = frozenFrameImage
            state.isRoundFrozen = true
            state.isRoundActive = false
        }
    }

    private func makeFrozenFrameImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        print("makeFrozenImage...........")
        return UIImage(cgImage: cgImage)
    }

    private func updateCameraError(_ message: String?) {
        updateState { state in
            state.cameraErrorMessage = message
        }
    }

    private func updateState(_ update: @escaping (inout CameraHandPoseState) -> Void) {
        let applyUpdate = {
            var nextState = self.state
            update(&nextState)
            self.state = nextState
        }

        if Thread.isMainThread {
            applyUpdate()
        } else {
            DispatchQueue.main.async(execute: applyUpdate)
        }
    }
}

extension CameraHandPoseClassifier: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        let now = Date()

        switch roundState.phase {
        case .idle, .frozen:
            return
        case .waitingForGesture:
            break
        case .countdown:
            updateState { state in
                state.countdownRemaining = self.roundState.countdownRemaining(at: now)
            }

            if roundState.freezeIfNeeded(at: now) {
                freezeRound(using: pixelBuffer)
            }

            return
        }

        guard !isProcessingFrame else { return }

        isProcessingFrame = true
        if predictMove(in: pixelBuffer) != nil {
            startCountdown(at: now)
        }
        isProcessingFrame = false
    }
}
