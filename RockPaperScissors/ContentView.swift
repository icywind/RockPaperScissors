//
//  ContentView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/8/26.
//

import SwiftUI

enum HandMove: String, CaseIterable {
    case rock = "Rock"
    case paper = "Paper"
    case scissors = "Scissors"

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
    @State private var player1Move: HandMove?
    @State private var player2Move: HandMove?
    @State private var resultText = "Tap Start Game to begin"

    var body: some View {
        VStack(spacing: 18) {
            PlayerAreaView(
                title: "Player 1",
                subtitle: "Computer vision input",
                move: player1Move,
                accentColor: .blue
            )

            ResultBoxView(resultText: resultText)

            PlayerAreaView(
                title: "Player 2 (AI)",
                subtitle: "AI opponent",
                move: player2Move,
                accentColor: .purple
            )

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
    }

    private func startGame() {
        let playerOne = HandMove.allCases.randomElement() ?? .rock
        let playerTwo = HandMove.allCases.randomElement() ?? .rock

        player1Move = playerOne
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

private struct PlayerAreaView: View {
    let title: String
    let subtitle: String
    let move: HandMove?
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(accentColor.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(accentColor.opacity(0.35), lineWidth: 1.5)
                    )

                VStack(spacing: 10) {
                    Image(systemName: move?.symbolName ?? "hand.raised.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(accentColor)
                    Text(move?.rawValue ?? "Waiting for move")
                        .font(.headline)
                    Text("Player canvas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
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

#Preview {
    ContentView()
}
