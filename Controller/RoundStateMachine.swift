import Foundation

struct RoundStateMachine {
    enum Phase: Equatable {
        case idle
        case waitingForGesture
        case countdown(freezeDeadline: Date)
        case frozen
    }

    private(set) var phase: Phase = .idle

    var isRoundActive: Bool {
        switch phase {
        case .waitingForGesture, .countdown:
            return true
        case .idle, .frozen:
            return false
        }
    }

    var isRoundFrozen: Bool {
        if case .frozen = phase {
            return true
        }

        return false
    }

    mutating func beginRound() {
        phase = .waitingForGesture
    }

    mutating func reset() {
        phase = .idle
    }

    mutating func registerDetectedGesture(at now: Date, freezeAfter duration: TimeInterval) -> Date? {
        guard case .waitingForGesture = phase else {
            return nil
        }

        let deadline = now.addingTimeInterval(duration)
        phase = .countdown(freezeDeadline: deadline)
        return deadline
    }

    func countdownRemaining(at now: Date) -> Int? {
        guard case let .countdown(freezeDeadline) = phase else {
            return nil
        }

        let remaining = freezeDeadline.timeIntervalSince(now)
        guard remaining > 0 else {
            return nil
        }

        return Int(ceil(remaining))
    }

    mutating func freezeIfNeeded(at now: Date) -> Bool {
        guard case let .countdown(freezeDeadline) = phase, now >= freezeDeadline else {
            return false
        }

        phase = .frozen
        return true
    }
}