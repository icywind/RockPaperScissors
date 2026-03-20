import AVFoundation
import XCTest
@testable import RockPaperScissors

final class GameControllerTests: XCTestCase {
    func testAuthorizedStartRoundMessageMatchesExpectedCopy() {
        let controller = GameController()

        XCTAssertEqual(
            controller.startRoundMessage(for: .authorized),
            "Show your hand to the camera. The first detected gesture starts a 3-second timer."
        )
    }

    func testConcludeRoundReturnsRetryMessageWhenNoMoveRecognized() {
        let controller = GameController()
        let outcome = controller.concludeRound(playerOneMove: nil)

        XCTAssertNil(outcome.playerTwoMove)
        XCTAssertEqual(
            outcome.resultText,
            "No gesture was recognized from the frozen frame. Choose Rock, Paper, or Scissors to try again."
        )
    }

    func testConcludeRoundKeepsSelectedPlayerTwoMoveWhenNoMoveRecognized() {
        let controller = GameController()
        let outcome = controller.concludeRound(playerOneMove: nil, playerTwoMove: .paper)

        XCTAssertEqual(outcome.playerTwoMove, .paper)
        XCTAssertEqual(
            outcome.resultText,
            "No gesture was recognized from the frozen frame. Choose Rock, Paper, or Scissors to try again."
        )
    }

    func testConcludeRoundReturnsWinningMessageForPlayerOne() {
        let controller = GameController(randomMoveProvider: { .scissors })
        let outcome = controller.concludeRound(playerOneMove: .rock)

        XCTAssertEqual(outcome.playerTwoMove, .scissors)
        XCTAssertEqual(outcome.resultText, "Player 1 wins with Rock!")
    }

    func testConcludeRoundUsesSelectedPlayerTwoMoveInsteadOfRandomProvider() {
        let controller = GameController(randomMoveProvider: { .paper })
        let outcome = controller.concludeRound(playerOneMove: .rock, playerTwoMove: .scissors)

        XCTAssertEqual(outcome.playerTwoMove, .scissors)
        XCTAssertEqual(outcome.resultText, "Player 1 wins with Rock!")
    }

    func testPlayerCameraViewModelPlayerMoveLabelPrefersRecognizedMove() {
        XCTAssertEqual(
            PlayerCameraViewModel.playerMoveLabel(
                recognizedMove: .paper,
                countdownRemaining: 2,
                isRoundFrozen: true,
                cameraErrorMessage: "Error",
                authorizationStatus: .denied,
                isRoundActive: false
            ),
            "Paper"
        )
    }

    func testPlayerCameraViewModelOverlayTextMatchesAuthorizedPrompt() {
        XCTAssertEqual(
            PlayerCameraViewModel.cameraOverlayText(
                cameraErrorMessage: nil,
                authorizationStatus: .authorized,
                isRoundActive: true
            ),
            "Show your move to start the countdown."
        )
    }

    func testPlayerCameraViewModelPlayerMoveLabelReflectsMoveSelectionPromptWhenIdle() {
        XCTAssertEqual(
            PlayerCameraViewModel.playerMoveLabel(
                recognizedMove: nil,
                countdownRemaining: nil,
                isRoundFrozen: false,
                cameraErrorMessage: nil,
                authorizationStatus: .authorized,
                isRoundActive: false
            ),
            "Choose Rock, Paper, or Scissors to begin"
        )
    }
}