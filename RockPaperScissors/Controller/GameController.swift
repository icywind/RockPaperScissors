import AVFoundation

struct GameRoundOutcome {
    let playerTwoMove: HandMove?
    let resultText: String
}

enum PlayerType : Int, Codable {
    case human = 0
    case computer = 1
    case buttonpusher = 2
    
}

struct GameController {
    let playerOneType: PlayerType
    let playerTwoType: PlayerType
    
    var randomMoveProvider: () -> HandMove = {
        HandMove.allCases.randomElement() ?? .rock
    }

    func startRoundMessage(for authorizationStatus: AVAuthorizationStatus) -> String {
        switch authorizationStatus {
        case .denied, .restricted:
            return "Camera access is required to recognize Player 1's move."
        case .authorized:
            if playerOneType == .human {
               return "Show your hand to the camera. The first detected gesture starts a 3-second timer."
            }
            return "Press Paper, Rock or Scissor button to Start!"
        case .notDetermined:
            return "Waiting for camera permission. Please allow access to start the game."
        @unknown default:
            return "Camera status is unavailable right now."
        }
    }

    func countdownMessage(remaining: Int) -> String {
        "Gesture detected. Hold still — capturing in \(remaining) seconds."
    }

    func concludeRound(playerOneMove: HandMove?, playerTwoMove: HandMove? = nil) -> GameRoundOutcome {
        guard let playerOneMove else {
            return GameRoundOutcome(
                playerTwoMove: playerTwoMove,
                resultText: "No gesture was recognized from the frozen frame. Choose Rock, Paper, or Scissors to try again."
            )
        }

        let playerTwoMove = playerTwoMove ?? randomMoveProvider()

        if playerOneMove == playerTwoMove {
            return GameRoundOutcome(
                playerTwoMove: playerTwoMove,
                resultText: "It's a tie! Both players picked \(playerOneMove.rawValue)."
            )
        }

        if playerOneMove.beats(playerTwoMove) {
            return GameRoundOutcome(
                playerTwoMove: playerTwoMove,
                resultText: "Player 1 wins with \(playerOneMove.rawValue)!"
            )
        }

        return GameRoundOutcome(
            playerTwoMove: playerTwoMove,
            resultText: "Player 2 (AI) wins with \(playerTwoMove.rawValue)!"
        )
    }
}
