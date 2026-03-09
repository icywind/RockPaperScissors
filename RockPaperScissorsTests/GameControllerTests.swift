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
            "No gesture was recognized from the frozen frame. Press Start Game to try again."
        )
    }

    func testConcludeRoundReturnsWinningMessageForPlayerOne() {
        let controller = GameController(randomMoveProvider: { .scissors })
        let outcome = controller.concludeRound(playerOneMove: .rock)

        XCTAssertEqual(outcome.playerTwoMove, .scissors)
        XCTAssertEqual(outcome.resultText, "Player 1 wins with Rock!")
    }
}