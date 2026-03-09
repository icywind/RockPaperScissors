//
//  ContentView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/8/26.
//

import AVFoundation
import Combine
import CoreImage
import CoreML
import ImageIO
import SwiftUI
import UIKit
import Vision

enum HandMove: String, CaseIterable {
    case rock = "Rock"
    case paper = "Paper"
    case scissors = "Scissors"

    init?(modelLabel: String) {
        switch modelLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "rock":
            self = .rock
        case "paper":
            self = .paper
        case "scissors":
            self = .scissors
        default:
            return nil
        }
    }

    var symbolName: String {
        switch self {
        case .rock:
            return "circle.fill"
        case .paper:
            return "doc.fill"
        case .scissors:
            return "scissors"
        }
    }
}

struct ContentView: View {
    @StateObject private var cameraClassifier = CameraHandPoseClassifier()
    @State private var player2Move: HandMove?
    @State private var resultText = "Tap Start Game to begin."

    var body: some View {
        VStack(spacing: 18) {
            PlayerCameraAreaView(cameraClassifier: cameraClassifier)

            ResultBoxView(resultText: resultText)

            AIPlayerAreaView(move: player2Move)

            Button(action: startGame) {
                Text("Start Game")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            cameraClassifier.requestCameraAccessIfNeeded()
        }
        .onDisappear {
            cameraClassifier.stopSession()
        }
        .onChange(of: cameraClassifier.countdownRemaining) { remaining in
            guard let remaining else { return }
            resultText = "Gesture detected. Hold still — capturing in \(remaining) seconds."
        }
        .onChange(of: cameraClassifier.isRoundFrozen) { isRoundFrozen in
            guard isRoundFrozen else { return }
            concludeRound()
        }
    }

    private func startGame() {
        player2Move = nil
        cameraClassifier.beginRound()
        resultText = startRoundMessage
    }

    private var startRoundMessage: String {
        switch cameraClassifier.authorizationStatus {
        case .denied, .restricted:
            return "Camera access is required to recognize Player 1's move."
        case .authorized:
            return "Show your hand to the camera. The first detected gesture starts a 3-second timer."
        case .notDetermined:
            return "Waiting for camera permission. Please allow access to start the game."
        @unknown default:
            return "Camera status is unavailable right now."
        }
    }

    private func concludeRound() {
        guard let playerOne = cameraClassifier.recognizedMove else {
            player2Move = nil
            resultText = "No gesture was recognized from the frozen frame. Press Start Game to try again."
            return
        }

        let playerTwo = HandMove.allCases.randomElement() ?? .rock
        player2Move = playerTwo

        if playerOne == playerTwo {
            resultText = "It's a tie! Both players picked \(playerOne.rawValue)."
        } else if beats(playerOne, playerTwo) {
            resultText = "Player 1 wins with \(playerOne.rawValue)!"
        } else {
            resultText = "Player 2 (AI) wins with \(playerTwo.rawValue)!"
        }
    }

    private func beats(_ lhs: HandMove, _ rhs: HandMove) -> Bool {
        switch (lhs, rhs) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
            return true
        default:
            return false
        }
    }
}

private struct PlayerCameraAreaView: View {
    @ObservedObject var cameraClassifier: CameraHandPoseClassifier

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Player 1")
                    .font(.title3.weight(.semibold))
                Text("Front camera hand gesture recognition")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.blue.opacity(0.12))

                if let frozenFrameImage = cameraClassifier.frozenFrameImage {
                    Image(uiImage: frozenFrameImage)
                        .resizable()
                        .scaledToFill()
                } else if cameraClassifier.authorizationStatus == .authorized {
                    CameraPreviewView(session: cameraClassifier.session)
                } else {
                    CameraStatusPlaceholder(message: cameraClassifier.cameraOverlayText)
                        .padding()
                }

                if let countdownRemaining = cameraClassifier.countdownRemaining {
                    VStack {
                        HStack {
                            Spacer()

                            Text("\(countdownRemaining)")
                                .font(.headline.monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.black.opacity(0.65))
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.blue.opacity(0.35), lineWidth: 1.5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 4) {
                Text("Player move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(cameraClassifier.playerMoveLabel)
                    .font(.headline)
            }
        }
    }
}

private struct AIPlayerAreaView: View {
    let move: HandMove?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Player 2 (AI)")
                    .font(.title3.weight(.semibold))
                Text("Computer opponent")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.purple.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.purple.opacity(0.35), lineWidth: 1.5)
                    )

                VStack(spacing: 10) {
                    Image(systemName: move?.symbolName ?? "cpu")
                        .font(.system(size: 52))
                        .foregroundStyle(.purple)
                    Text(move?.rawValue ?? "Waiting for game")
                        .font(.headline)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI move")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(move?.rawValue ?? "Pending")
                    .font(.headline)
            }
        }
    }
}

private struct ResultBoxView: View {
    let resultText: String

    var body: some View {
        Text(resultText)
            .font(.headline)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct CameraStatusPlaceholder: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
            Text(message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session

        if let connection = uiView.previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = true
            }
        }
    }
}

private final class PreviewContainerView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

private final class CameraHandPoseClassifier: NSObject, ObservableObject {
    @Published private(set) var recognizedMove: HandMove?
    @Published private(set) var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var cameraErrorMessage: String?
    @Published private(set) var countdownRemaining: Int?
    @Published private(set) var frozenFrameImage: UIImage?
    @Published private(set) var isRoundFrozen = false
    @Published private(set) var isRoundActive = false

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

    private var classifierModel: RockPaperScissorClassifier?
    private var analysisState: AnalysisState = .idle
    private var shouldBeginRoundWhenAuthorized = false
    private var isSessionConfigured = false
    private var isProcessingFrame = false
    private var freezeDeadline: Date?
    private var countdownTimer: DispatchSourceTimer?

    private enum AnalysisState {
        case idle
        case waitingForGesture
        case countdown
    }

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
            self.analysisState = .waitingForGesture
            self.freezeDeadline = nil
            self.isProcessingFrame = false
        }

        DispatchQueue.main.async {
            self.countdownTimer?.cancel()
            self.countdownTimer = nil
            self.countdownRemaining = nil
            self.recognizedMove = nil
            self.frozenFrameImage = nil
            self.isRoundFrozen = false
            self.isRoundActive = true
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

    private func startCountdown() {
        analysisState = .countdown
        freezeDeadline = Date().addingTimeInterval(3)

        DispatchQueue.main.async {
            self.countdownTimer?.cancel()

            let timer = DispatchSource.makeTimerSource(queue: .main)
            self.countdownRemaining = 3
            timer.schedule(deadline: .now() + 1, repeating: 1)
            timer.setEventHandler { [weak self] in
                guard let self else { return }
                guard let countdownRemaining = self.countdownRemaining else {
                    timer.cancel()
                    return
                }

                if countdownRemaining > 1 {
                    self.countdownRemaining = countdownRemaining - 1
                } else {
                    self.countdownRemaining = nil
                    self.countdownTimer = nil
                    timer.cancel()
                }
            }

            self.countdownTimer = timer
            timer.resume()
        }
    }

    private func freezeRound(using pixelBuffer: CVPixelBuffer) {
        analysisState = .idle
        freezeDeadline = nil

        let frozenFrameImage = makeFrozenFrameImage(from: pixelBuffer)
        let recognizedMove = predictMove(in: pixelBuffer)

        stopSession()

        DispatchQueue.main.async {
            self.countdownTimer?.cancel()
            self.countdownTimer = nil
            self.countdownRemaining = nil
            self.recognizedMove = recognizedMove
            self.frozenFrameImage = frozenFrameImage
            self.isRoundFrozen = true
            self.isRoundActive = false
        }
    }

    private func makeFrozenFrameImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.leftMirrored)

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

        switch analysisState {
        case .idle:
            return
        case .waitingForGesture:
            break
        case .countdown:
            if let freezeDeadline, Date() >= freezeDeadline {
                freezeRound(using: pixelBuffer)
            }
            return
        }

        guard !isProcessingFrame else { return }

        isProcessingFrame = true
        if predictMove(in: pixelBuffer) != nil {
            startCountdown()
        }
        isProcessingFrame = false
    }
}

#Preview {
    ContentView()
}
