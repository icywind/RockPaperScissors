//
//  BvsP1View.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/21/26.
//

import SwiftUI

/// Bear vs Human play
///   Bear only presses the buttons to send move
struct BvsP1View: View {
    let roomName: String
    @StateObject private var rtcViewModel: AgoraViewModel
    @StateObject private var gameViewModel: GameViewModel
    @State private var showTieEffect = false
    @State private var isLoading = true
    
    @State private var remoteUIView = UIView()
    
    // MARK: - struct init
    init(roomName: String) {
        self.roomName = roomName
        let rtcVM = AgoraViewModel(channelName: roomName)
        _rtcViewModel = StateObject(wrappedValue: rtcVM)
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .buttonpusher, player2Type: .human, rtcViewModel: rtcVM))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 18) {
                    Player2ContainerView(
                    player2Name: "Player 1",
                    player2Description: "Remote user",
                    subView:
                        VideoContainerView(uiView: remoteUIView)
                            .background(Color.white)
                            .cornerRadius(8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
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
                            let msg = NetworkMessage(
                                requiredP1Mode: .human,
                                remoteP2Mode: .buttonpusher,
                                remoteP2Move: move
                            )
                            rtcViewModel.sendMessage(message: msg)
                        }) {
                            Image(bearImageName(for: move))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .background(
                                    gameViewModel.selectedTargetMove == move
                                        ? Color.accentColor
                                        : Color.accentColor.opacity(0.85)
                                )
                                .clipShape(Circle())
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
                
                TextEffectView(showText:gameViewModel.player1Outcome?.rawValue ?? "", isShowing: showTieEffect) {
                    showTieEffect = false
                    gameViewModel.resetPlayer1Outcome()
                }
            }
            .onAppear {
                Task {
                    isLoading = true
                    rtcViewModel.onAppear(remoteView: remoteUIView)
                    try await Task.sleep(for: .seconds(0.5))
                    gameViewModel.onAppear()
                    isLoading = false
                }
                // Set up network message handler to receive Player1's move
                rtcViewModel.onNetworkMessageReceived = { message in
                    // In BvsP1View, we receive the Player1's move back
                    // Determine the game result using the remote player's move
                    print("Received Player1's move: \(message.remoteP2Move)")
                    
                    // Get the local player's (Bear/Player 2) move from the game view model
                    guard let localMove = gameViewModel.selectedTargetMove else {
                        print("No local move selected yet")
                        return
                    }
                    
                    // Determine the winner using GameController
                    let gameController = GameController(playerOneType: .buttonpusher, playerTwoType: .human)
                    let outcome = gameController.concludeRound(
                        playerOneMove: message.remoteP2Move,
                        playerTwoMove: localMove
                    )
                    
                    // Update the game view model with the result
                    gameViewModel.updateResultFromNetwork(
                        player2Move: outcome.playerTwoMove,
                        resultText: outcome.resultText
                    )
                }
            }
        .onDisappear {
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Room: \(roomName)")
                        .font(.subheadline)
                        .foregroundStyle(Color.yellow)
                }
            }
        }
    }
}

private func bearImageName(for move: HandMove) -> String {
    switch move {
    case .rock:
        return "bear-rock"
    case .paper:
        return "bear-paper"
    case .scissors:
        return "bear-scissors"
    }
}

#Preview {
    BvsP1View(roomName: "preview-room")
}
