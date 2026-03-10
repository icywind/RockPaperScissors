import AVFoundation
import Combine
import CoreImage
import CoreML
import Photos
import UIKit
import Vision

final class CameraHandPoseClassifier: NSObject, ObservableObject {
    @Published private(set) var recognizedMove: HandMove?
    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var cameraErrorMessage: String?
    @Published private(set) var countdownRemaining: Int?
    @Published private(set) var frozenFrameImage: UIImage?
    @Published private(set) var isRoundFrozen = false
    @Published private(set) var isRoundActive = false
    @Published private(set) var isFrozenImageSaved = false

    let session = AVCaptureSession()

    var playerMoveLabel: String {
        if let recognizedMove {
            return recognizedMove.rawValue
        }

        if let countdownRemaining {
            return "Hold still... capturing in \(countdownRemaining)s"
        }

        if isRoundFrozen {
            return "No gesture recognized"
        }

        if let cameraErrorMessage {
            return cameraErrorMessage
        }

        switch authorizationStatus {
        case .authorized:
            return isRoundActive ? "Show rock, paper, or scissors" : "Tap Start Game to begin"
        case .notDetermined:
            return "Requesting camera access..."
        case .denied, .restricted:
            return "Camera unavailable"
        @unknown default:
            return "Waiting for camera"
        }
    }

    var cameraOverlayText: String {
        if let cameraErrorMessage {
            return cameraErrorMessage
        }

        switch authorizationStatus {
        case .authorized:
            return isRoundActive ? "Show your move to start the countdown." : "Tap Start Game to begin."
        case .notDetermined:
            return "Please allow camera access to recognize hand gestures."
        case .denied, .restricted:
            return "Camera access is required to play using hand gestures."
        @unknown default:
            return "Camera status is unavailable."
        }
    }

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

    override init() {
        super.init()

        handPoseRequest.maximumHandCount = 1

        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        classifierModel = try? RockPaperScissorClassifier(configuration: configuration)

        if classifierModel == nil {
            cameraErrorMessage = "Unable to load the hand gesture classifier."
        }
    }

    func requestCameraAccessIfNeeded() {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = currentStatus

        switch currentStatus {
        case .authorized:
            startSession()
            if shouldBeginRoundWhenAuthorized {
                beginRound()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                }

                if granted {
                    self?.startSession()
                    if self?.shouldBeginRoundWhenAuthorized == true {
                        self?.beginRound()
                    }
                }
            }
        case .denied, .restricted:
            cameraErrorMessage = "Enable camera access in Settings to recognize your move."
        @unknown default:
            cameraErrorMessage = "Camera permission is unavailable."
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
            cameraErrorMessage = "Enable camera access in Settings to recognize your move."
        @unknown default:
            cameraErrorMessage = "Camera permission is unavailable."
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
        }
    }

    func saveFrozenFrame(onCompletion: ((Bool) -> Void)? = nil) {
        guard let image = frozenFrameImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async { [weak self] in
                        if success {
                            self?.isFrozenImageSaved = true
                        } else {
                            self?.saveError = error?.localizedDescription ?? "Failed to save image"
                        }
                        onCompletion?(success)
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async { [weak self] in
                    self?.saveError = "Photo library access is denied"
                    onCompletion?(false)
                }
            case .notDetermined:
                DispatchQueue.main.async { [weak self] in
                    self?.saveError = "Photo library permission not determined"
                    onCompletion?(false)
                }
            @unknown default:
                DispatchQueue.main.async { [weak self] in
                    self?.saveError = "Unknown error occurred"
                    onCompletion?(false)
                }
            }
        }
    }

    @Published var saveError: String?

    private func startSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            if !self.isSessionConfigured {
                self.configureSession()
            }

            guard self.isSessionConfigured, !self.session.isRunning else { return }
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

        DispatchQueue.main.async {
            self.countdownRemaining = nil
            self.recognizedMove = nil
            self.frozenFrameImage = nil
            self.isRoundFrozen = false
            self.isRoundActive = true
            self.isFrozenImageSaved = false
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

        let countdownRemaining = roundState.countdownRemaining(at: now)
        DispatchQueue.main.async {
            self.countdownRemaining = countdownRemaining
        }
    }

    private func freezeRound(using pixelBuffer: CVPixelBuffer) {
        let frozenFrameImage = makeFrozenFrameImage(from: pixelBuffer)
        let recognizedMove = predictMove(in: pixelBuffer)

        stopSession()

        DispatchQueue.main.async {
            self.countdownRemaining = nil
            self.recognizedMove = recognizedMove
            self.frozenFrameImage = frozenFrameImage
            self.isRoundFrozen = true
            self.isRoundActive = false
        }
    }

    private func makeFrozenFrameImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.up)

        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func updateCameraError(_ message: String?) {
        DispatchQueue.main.async {
            self.cameraErrorMessage = message
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
            let countdownRemaining = roundState.countdownRemaining(at: now)
            DispatchQueue.main.async {
                self.countdownRemaining = countdownRemaining
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
