import XCTest
@testable import RockPaperScissors

final class RoundStateMachineTests: XCTestCase {
    func testBeginRoundMovesToWaitingForGesture() {
        var roundState = RoundStateMachine()

        roundState.beginRound()

        XCTAssertEqual(roundState.phase, .waitingForGesture)
        XCTAssertTrue(roundState.isRoundActive)
        XCTAssertFalse(roundState.isRoundFrozen)
    }

    func testFirstGestureStartsThreeSecondCountdown() {
        var roundState = RoundStateMachine()
        let start = Date(timeIntervalSinceReferenceDate: 100)

        roundState.beginRound()
        let deadline = roundState.registerDetectedGesture(at: start, freezeAfter: 3)

        XCTAssertEqual(deadline, start.addingTimeInterval(3))
        XCTAssertEqual(roundState.countdownRemaining(at: start), 3)
        XCTAssertEqual(roundState.countdownRemaining(at: start.addingTimeInterval(1.01)), 2)
        XCTAssertEqual(roundState.countdownRemaining(at: start.addingTimeInterval(2.01)), 1)
        XCTAssertNil(roundState.countdownRemaining(at: start.addingTimeInterval(3)))
    }

    func testRepeatedGestureDoesNotRestartCountdown() {
        var roundState = RoundStateMachine()
        let start = Date(timeIntervalSinceReferenceDate: 200)

        roundState.beginRound()
        let firstDeadline = roundState.registerDetectedGesture(at: start, freezeAfter: 3)
        let secondDeadline = roundState.registerDetectedGesture(at: start.addingTimeInterval(1), freezeAfter: 3)

        XCTAssertEqual(firstDeadline, start.addingTimeInterval(3))
        XCTAssertNil(secondDeadline)
        XCTAssertEqual(roundState.phase, .countdown(freezeDeadline: start.addingTimeInterval(3)))
    }

    func testFreezeOccursOnlyAtOrAfterDeadline() {
        var roundState = RoundStateMachine()
        let start = Date(timeIntervalSinceReferenceDate: 300)

        roundState.beginRound()
        _ = roundState.registerDetectedGesture(at: start, freezeAfter: 3)

        XCTAssertFalse(roundState.freezeIfNeeded(at: start.addingTimeInterval(2.99)))
        XCTAssertEqual(roundState.phase, .countdown(freezeDeadline: start.addingTimeInterval(3)))

        XCTAssertTrue(roundState.freezeIfNeeded(at: start.addingTimeInterval(3)))
        XCTAssertEqual(roundState.phase, .frozen)
        XCTAssertTrue(roundState.isRoundFrozen)
        XCTAssertFalse(roundState.isRoundActive)
    }

    func testBeginRoundAfterFreezeResetsFrozenState() {
        var roundState = RoundStateMachine()
        let start = Date(timeIntervalSinceReferenceDate: 400)

        roundState.beginRound()
        _ = roundState.registerDetectedGesture(at: start, freezeAfter: 3)
        XCTAssertTrue(roundState.freezeIfNeeded(at: start.addingTimeInterval(3)))

        roundState.beginRound()

        XCTAssertEqual(roundState.phase, .waitingForGesture)
        XCTAssertNil(roundState.countdownRemaining(at: start.addingTimeInterval(4)))
        XCTAssertFalse(roundState.isRoundFrozen)
        XCTAssertTrue(roundState.isRoundActive)
    }
}