import Combine
import Foundation

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var player2Move: HandMove?
    @Published private(set) var resultText = "Tap Start Game to begin."

    let cameraClassifier: CameraHandPoseClassifier

    private let gameController: GameController
    private var cancellables = Set<AnyCancellable>()

    init(
        cameraClassifier: CameraHandPoseClassifier? = nil,
        gameController: GameController? = nil
    ) {
        self.cameraClassifier = cameraClassifier ?? CameraHandPoseClassifier()
        self.gameController = gameController ?? GameController()
        bindCameraState()
    }

    func onAppear() {
        cameraClassifier.requestCameraAccessIfNeeded()
    }

    func onDisappear() {
        cameraClassifier.stopSession()
    }

    func startGame() {
        player2Move = nil
        cameraClassifier.beginRound()
        resultText = gameController.startRoundMessage(for: cameraClassifier.authorizationStatus)
    }

    private func bindCameraState() {
        cameraClassifier.$countdownRemaining
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] remaining in
                self?.resultText = self?.gameController.countdownMessage(remaining: remaining) ?? ""
            }
            .store(in: &cancellables)

        cameraClassifier.$isRoundFrozen
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.concludeRound()
            }
            .store(in: &cancellables)
    }

    private func concludeRound() {
        let outcome = gameController.concludeRound(playerOneMove: cameraClassifier.recognizedMove)
        player2Move = outcome.playerTwoMove
        resultText = outcome.resultText
    }
}