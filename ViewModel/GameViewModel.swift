import AVFoundation
import Combine
import Foundation
import Photos
import UIKit

enum Player1Outcome {
    case win
    case lose
    case tie
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var player2Move: HandMove?
    @Published private(set) var resultText = "Show your hand to the camera. The first detected gesture starts a 3-second timer."
    @Published private(set) var isShuffling = false
    @Published private(set) var shufflingMove: HandMove?
    @Published private(set) var player1Outcome: Player1Outcome?

    let playerCameraViewModel: PlayerCameraViewModel

    private let gameController: GameController
    private var cancellables = Set<AnyCancellable>()
    private var shuffleTimer: Timer?

    init(
        playerCameraViewModel: PlayerCameraViewModel? = nil,
        gameController: GameController? = nil
    ) {
        self.playerCameraViewModel = playerCameraViewModel ?? PlayerCameraViewModel()
        self.gameController = gameController ?? GameController()
        bindCameraState()
    }

    func onAppear() {
        playerCameraViewModel.requestCameraAccessIfNeeded()
    }

    func onDisappear() {
        playerCameraViewModel.stopSession()
    }

    func startGame() {
        player2Move = nil
        isShuffling = true
        shufflingMove = .allCases.randomElement()
        player1Outcome = nil
        startShuffleTimer()
        playerCameraViewModel.beginRound()
        resultText = gameController.startRoundMessage(for: playerCameraViewModel.authorizationStatus)
    }
    
    private func startShuffleTimer() {
        shuffleTimer?.invalidate()
        shuffleTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.shufflingMove = HandMove.allCases.randomElement()
            }
        }
    }
    
    private func stopShuffleTimer() {
        shuffleTimer?.invalidate()
        shuffleTimer = nil
        isShuffling = false
    }

    private func bindCameraState() {
        playerCameraViewModel.$countdownRemaining
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.resultText = self?.gameController.countdownMessage(remaining: remaining) ?? ""
            }
            .store(in: &cancellables)

        playerCameraViewModel.$isRoundFrozen
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.concludeRound()
            }
            .store(in: &cancellables)
    }

    private func concludeRound() {
        stopShuffleTimer()
        let outcome = gameController.concludeRound(playerOneMove: playerCameraViewModel.recognizedMove)
        player2Move = outcome.playerTwoMove
        resultText = outcome.resultText
        
        // Determine player 1 outcome for special effects
        if outcome.resultText.contains("Player 1 wins") {
            player1Outcome = .win
        } else if outcome.resultText.contains("Player 2 (AI) wins") {
            player1Outcome = .lose
        } else {
            player1Outcome = .tie
        }
    }
}

@MainActor
final class PlayerCameraViewModel: ObservableObject {
    @Published private(set) var authorizationStatus: AVAuthorizationStatus
    @Published private(set) var cameraErrorMessage: String?
    @Published private(set) var countdownRemaining: Int?
    @Published private(set) var frozenFrameImage: UIImage?
    @Published private(set) var recognizedMove: HandMove?
    @Published private(set) var isRoundFrozen: Bool
    @Published private(set) var isRoundActive: Bool
    @Published private(set) var isFrozenImageSaved = false

    var session: AVCaptureSession {
        cameraClassifier.session
    }

    var playerMoveLabel: String {
        Self.playerMoveLabel(
            recognizedMove: recognizedMove,
            countdownRemaining: countdownRemaining,
            isRoundFrozen: isRoundFrozen,
            cameraErrorMessage: cameraErrorMessage,
            authorizationStatus: authorizationStatus,
            isRoundActive: isRoundActive
        )
    }

    var cameraOverlayText: String {
        Self.cameraOverlayText(
            cameraErrorMessage: cameraErrorMessage,
            authorizationStatus: authorizationStatus,
            isRoundActive: isRoundActive
        )
    }

    private let cameraClassifier: CameraHandPoseClassifier
    private var cancellables = Set<AnyCancellable>()

    init(cameraClassifier: CameraHandPoseClassifier? = nil) {
        let cameraClassifier = cameraClassifier ?? CameraHandPoseClassifier()
        self.cameraClassifier = cameraClassifier

        let state = cameraClassifier.state
        authorizationStatus = state.authorizationStatus
        cameraErrorMessage = state.cameraErrorMessage
        countdownRemaining = state.countdownRemaining
        frozenFrameImage = state.frozenFrameImage
        recognizedMove = state.recognizedMove
        isRoundFrozen = state.isRoundFrozen
        isRoundActive = state.isRoundActive

        bindClassifierState()
    }

    func requestCameraAccessIfNeeded() {
        cameraClassifier.requestCameraAccessIfNeeded()
    }

    func beginRound() {
        isFrozenImageSaved = false
        cameraClassifier.beginRound()
    }

    func stopSession() {
        cameraClassifier.stopSession()
    }

    func saveFrozenFrame(onCompletion: ((String) -> Void)? = nil) {
        guard let image = frozenFrameImage else { return }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            switch status {
            case .authorized, .limited:
                PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                } completionHandler: { success, error in
                    DispatchQueue.main.async {
                        if success {
                            self?.isFrozenImageSaved = true
                            onCompletion?("Image saved to photo library")
                        } else {
                            onCompletion?(error?.localizedDescription ?? "Failed to save image")
                        }
                    }
                }
            case .denied, .restricted:
                DispatchQueue.main.async {
                    onCompletion?("Photo library access is denied")
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    onCompletion?("Photo library permission not determined")
                }
            @unknown default:
                DispatchQueue.main.async {
                    onCompletion?("Unknown error occurred")
                }
            }
        }
    }

    static func playerMoveLabel(
        recognizedMove: HandMove?,
        countdownRemaining: Int?,
        isRoundFrozen: Bool,
        cameraErrorMessage: String?,
        authorizationStatus: AVAuthorizationStatus,
        isRoundActive: Bool
    ) -> String {
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

    static func cameraOverlayText(
        cameraErrorMessage: String?,
        authorizationStatus: AVAuthorizationStatus,
        isRoundActive: Bool
    ) -> String {
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

    private func bindClassifierState() {
        cameraClassifier.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.authorizationStatus = state.authorizationStatus
                self?.cameraErrorMessage = state.cameraErrorMessage
                self?.countdownRemaining = state.countdownRemaining
                self?.frozenFrameImage = state.frozenFrameImage
                self?.recognizedMove = state.recognizedMove
                self?.isRoundFrozen = state.isRoundFrozen
                self?.isRoundActive = state.isRoundActive

                if state.frozenFrameImage == nil {
                    self?.isFrozenImageSaved = false
                }
            }
            .store(in: &cancellables)
    }
}
