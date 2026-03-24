import Foundation

enum HandMove: String, CaseIterable, Codable {
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
    
    var imageName: String {
        switch self {
        case .rock:
            return "rock"
        case .paper:
            return "paper"
        case .scissors:
            return "scissors"
        }
    }

    func beats(_ other: HandMove) -> Bool {
        switch (self, other) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper):
            return true
        default:
            return false
        }
    }
}
