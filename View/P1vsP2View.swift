//
//  P1vsP2View.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct P1vsP2View: View {
    @StateObject private var gameViewModel = GameViewModel()
    @StateObject private var rtcViewModel = AgoraViewModel()
    @State private var showTieEffect = false
    @State private var isLoading = true

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
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            
            TieEffectView(isShowing: showTieEffect)
        }
        .onAppear {
            Task {
                isLoading = true
                rtcViewModel.onAppear()
                try await Task.sleep(for: .seconds(0.5))
                gameViewModel.onAppear()
                isLoading = false
            }
        }
        .onDisappear{
            gameViewModel.onDisappear()
            rtcViewModel.onDestory()
        }
        .onChange(of: gameViewModel.player1Outcome) { newValue in
            showTieEffect = (newValue == .tie)
        }
        .overlay {
            if isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                    ProgressView("Loading...")
                        .tint(.white)
                }
            }
        }

    }
}

#Preview {
    P1vsP2View()
}
