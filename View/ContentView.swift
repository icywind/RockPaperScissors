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

                Button(action: viewModel.startGame) {
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
