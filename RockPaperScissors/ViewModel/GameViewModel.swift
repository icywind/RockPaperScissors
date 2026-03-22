import AVFoundation
import Combine
import Foundation
import Photos
import UIKit
import SwiftUI

enum Player1Outcome {
    case win
    case lose
    case tie
}

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var player2Move: HandMove?
    @Published private(set) var resultText = "Choose Rock, Paper, or Scissors to start the game."
    @Published private(set) var isShuffling = false
    @Published private(set) var shufflingMove: HandMove?
    @Published private(set) var player1Outcome: Player1Outcome?
    @Published private(set) var selectedTargetMove: HandMove?

    let playerCameraViewModel: PlayerCameraViewModel
    let p1Type: PlayerType = .buttonpusher

    private let gameController: GameController
    private var cancellables = Set<AnyCancellable>()
    private var shuffleTimer: Timer?
    private weak var rtcViewModel: AgoraViewModel?
    private var audioPlayer: AVAudioPlayer?
    
    init(
        player1Type p1Type: PlayerType,
        playerCameraViewModel: PlayerCameraViewModel? = nil,
        gameController: GameController? = nil,
        rtcViewModel: AgoraViewModel? = nil,
    ) {
        self.playerCameraViewModel = playerCameraViewModel ?? PlayerCameraViewModel()
        self.gameController = gameController ?? GameController( playerOneType: p1Type)
        self.rtcViewModel = rtcViewModel
        bindCameraState()
        setupVideoFrameForwarding()
    }

    func onAppear() {
        playerCameraViewModel.requestCameraAccessIfNeeded()
    }

    func onDisappear() {
        stopShuffleTimer()
        stopAudio()
        selectedTargetMove = nil
        playerCameraViewModel.stopSession()
    }

    var areMoveSelectionButtonsDisabled: Bool {
        selectedTargetMove != nil
    }

    func startGame(with selectedMove: HandMove) {
        guard !areMoveSelectionButtonsDisabled else { return }

        let authorizationStatus = playerCameraViewModel.authorizationStatus
        player2Move = nil
        player1Outcome = nil
        resultText = gameController.startRoundMessage(for: authorizationStatus)

        switch authorizationStatus {
        case .authorized, .notDetermined:
            selectedTargetMove = selectedMove
            isShuffling = true
            shufflingMove = .allCases.randomElement()
            startShuffleTimer()
        case .denied, .restricted:
            selectedTargetMove = nil
            isShuffling = false
            shufflingMove = nil
        @unknown default:
            selectedTargetMove = nil
            isShuffling = false
            shufflingMove = nil
        }

        playerCameraViewModel.beginRound()
    }
    
    private func startShuffleTimer() {
        shuffleTimer?.invalidate()
        shuffleTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.shufflingMove = HandMove.allCases.randomElement()
            }
        }
        playAudio()
    }
    
    private func stopShuffleTimer() {
        shuffleTimer?.invalidate()
        shuffleTimer = nil
        isShuffling = false
        stopAudio()
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

        playerCameraViewModel.$authorizationStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }

                switch status {
                case .denied, .restricted:
                    guard self.selectedTargetMove != nil else { return }
                    self.stopShuffleTimer()
                    self.selectedTargetMove = nil
                    self.shufflingMove = nil
                    self.resultText = self.gameController.startRoundMessage(for: status)
                case .authorized, .notDetermined:
                    break
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func playAudio() {
        guard Settings.shared.isSoundEnabled else { return }
        
        guard let url = Bundle.main.url(forResource: "rsp", withExtension: "mp3") else {
            print("Could not find rsp.mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Could not play audio: \(error)")
        }
    }
    
    func updateSoundSetting(_ enabled: Bool) {
        Settings.shared.isSoundEnabled = enabled
        if !enabled {
            stopAudio()
        }
    }
    
    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func concludeRound() {
        stopShuffleTimer()
        let outcome = gameController.concludeRound(
            playerOneMove: playerCameraViewModel.recognizedMove,
            playerTwoMove: selectedTargetMove
        )
        player2Move = outcome.playerTwoMove
        resultText = outcome.resultText
        selectedTargetMove = nil
        shufflingMove = nil
        
        // Determine player 1 outcome for special effects
        if outcome.resultText.contains("Player 1 wins") {
            player1Outcome = .win
        } else if outcome.resultText.contains("Player 2 (AI) wins") {
            player1Outcome = .lose
        } else {
            player1Outcome = .tie
        }
    }
    
    private func setupVideoFrameForwarding() {
        // Connect camera classifier's video frames to Agora for external video push (only in P2P mode)
        if rtcViewModel != nil {
            playerCameraViewModel.cameraClassifier.onVideoFrameCaptured = { [weak self] pixelBuffer in
                self?.rtcViewModel?.pushVideoFrame(pixelBuffer: pixelBuffer)
            }
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

    let cameraClassifier: CameraHandPoseClassifier
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
            return isRoundActive ? "Show rock, paper, or scissors" : "Choose Rock, Paper, or Scissors to begin"
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
            return isRoundActive ? "Show your move to start the countdown." : "Choose Rock, Paper, or Scissors to begin."
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
