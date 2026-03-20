//
//  ContentView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/8/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showTieEffect = false

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                PlayerCameraAreaView(
                    viewModel: viewModel.playerCameraViewModel,
                    player1Outcome: viewModel.player1Outcome
                )

                ResultBoxView(resultText: viewModel.resultText)

                AIPlayerAreaView(
                    move: viewModel.player2Move,
                    isShuffling: viewModel.isShuffling,
                    shufflingMove: viewModel.shufflingMove
                )

                HStack(spacing: 12) {
                    ForEach(HandMove.allCases, id: \.rawValue) { move in
                        Button(action: {
                            viewModel.startGame(with: move)
                        }) {
                            Text(move.rawValue)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    viewModel.selectedTargetMove == move
                                        ? Color.accentColor
                                        : Color.accentColor.opacity(0.85)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.areMoveSelectionButtonsDisabled)
                        .opacity(
                            viewModel.areMoveSelectionButtonsDisabled && viewModel.selectedTargetMove != move
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
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
        .onChange(of: viewModel.player1Outcome) { newValue in
            showTieEffect = (newValue == .tie)
        }
    }
}

#Preview {
    ContentView()
}
