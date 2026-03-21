//
//  P1vsAIView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/8/26.
//

import SwiftUI

struct P1vsAIView: View {
    @StateObject private var gameViewModel = GameViewModel()
    @State private var showTieEffect = false

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                PlayerCameraAreaView(
                    viewModel: gameViewModel.playerCameraViewModel,
                    player1Outcome: gameViewModel.player1Outcome
                )

                ResultBoxView(resultText: gameViewModel.resultText)

                AIPlayerAreaView(
                    move: gameViewModel.player2Move,
                    isShuffling: gameViewModel.isShuffling,
                    shufflingMove: gameViewModel.shufflingMove
                )

                HStack(spacing: 12) {
                    ForEach(HandMove.allCases, id: \.rawValue) { move in
                        Button(action: {
                            gameViewModel.startGame(with: move)
                        }) {
                            Text(move.rawValue)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    gameViewModel.selectedTargetMove == move
                                        ? Color.accentColor
                                        : Color.accentColor.opacity(0.85)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(gameViewModel.areMoveSelectionButtonsDisabled)
                        .opacity(
                            gameViewModel.areMoveSelectionButtonsDisabled && gameViewModel.selectedTargetMove != move
                                ? 0.45
                                : 1
                        )
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            
            TieEffectView(isShowing: showTieEffect)
        }
        .onAppear {
            gameViewModel.onAppear()
        }
        .onDisappear(perform: gameViewModel.onDisappear)
        .onChange(of: gameViewModel.player1Outcome) { newValue in
            showTieEffect = (newValue == .tie)
        }
    }
}

#Preview {
    P1vsAIView()
}
