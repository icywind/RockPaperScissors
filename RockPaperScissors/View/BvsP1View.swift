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
    @State private var showTextEffect = false
    @State private var isLoading = true
    @State private var remoteUIView = UIView()
    @State private var alertMessage = ""
    @State private var showAlertMessage: Bool = false
    
    // MARK: - struct init
    init(roomName: String, rtcViewModel: AgoraViewModel? = nil) {
        self.roomName = roomName
        let rtcVM = rtcViewModel ?? AgoraViewModel(channelName: roomName)
        _rtcViewModel = StateObject(wrappedValue: rtcVM)
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .buttonpusher, player2Type: .human, rtcViewModel: rtcVM))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                ZStack(alignment: .bottomTrailing) {
                    Player2ContainerView(
                        player2Name: rtcViewModel.remotePlayerName ?? "????",
                        player2Description: "Remote user",
                        subView:
                            VideoContainerView(uiView: remoteUIView)
                            .background(Color.white)
                            .cornerRadius(8)
                            .frame(maxWidth: UIScreen.main.bounds.width - 24)
                            .frame(height: 220)
                    )
                    if UIScreen.main.bounds.height < 800 {
                        AIPlayerAreaView(
                            move: gameViewModel.player2Move,
                            isShuffling: gameViewModel.isShuffling,
                            shufflingMove: gameViewModel.shufflingMove
                        )
                        .frame(width: 100, height: 100)
                        .padding(8)
                    }
                }

                ResultBoxView(resultText: gameViewModel.resultText)
                
                if UIScreen.main.bounds.height >= 800 {
                    AIPlayerAreaView(
                        move: gameViewModel.player2Move,
                        isShuffling: gameViewModel.isShuffling,
                        shufflingMove: gameViewModel.shufflingMove
                    )
                    .frame(height: 200)
                    .padding(8)
                }
                
                handMoveButtonsView()
                .frame(maxHeight: .infinity)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            
            TextEffectView(showText:gameViewModel.getPlayer2Outcome(),
                           isShowing: showTextEffect) {
                showTextEffect = false
                gameViewModel.resetPlayer1Outcome()
            }
        }
        .onAppear {
            assert(!Secrets.agoraAppId.isEmpty, "Agora App ID is not configured! Please set AGORA_APP_ID in Secrets.xcconfig to use Realtime multiplayer modes.")
            assert(!Secrets.tokenServerURL.isEmpty || Secrets.agoraAppId.contains("#"), "Token server URL not configured. For production usage set AGORA_TOKEN_SERVER_URL in Secrets.xcconfig.")
            setupViewModels()
        }
        .onDisappear {
            gameViewModel.onDisappear()
            rtcViewModel.destroy()
        }
        .onChange(of: gameViewModel.player1Outcome) { newValue in
            if let _ = newValue {
                showTextEffect = true
            }
        }
        .onChange(of: rtcViewModel.hasRemoteUser) { hasRemoteUser in
            if hasRemoteUser {
                let savedName = Settings.shared.username
                let myName = savedName.isEmpty ? "Player 2" : savedName
                rtcViewModel.sendNameMessage(playerName: myName)
            } else if gameViewModel.isShuffling {
                // stop the game
                gameViewModel.resetGame()
                alertMessage = "Opponent left the game :("
                showAlertMessage = true
            }
        }
        .alert("Information", isPresented: $showAlertMessage) {
            Button("OK", role: .cancel) {
                showAlertMessage = false
            }
        } message: {
            Text(alertMessage)
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
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.yellow)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func bearImageName(for move: HandMove) -> String {
        "bear-\(move.imageName)"
    }
    
    private func handMoveButtonsView() -> some View {
        HStack(spacing: 12) {
            ForEach(HandMove.allCases, id: \.rawValue) { move in
                Button(action: {
                    gameViewModel.startGame(with: move)
                    let msg = GameMessage(
                        requiredP1Mode: .human,
                        remoteP2Mode: .buttonpusher,
                        remoteP2Move: move
                    )
                    rtcViewModel.sendMessage(message: msg)
                }) {
                    Image(bearImageName(for: move))
                        .resizable()
                        .scaledToFit()
                        .frame(width: min(120, (UIScreen.main.bounds.width - 48) / 3), height: min(120, (UIScreen.main.bounds.width - 48) / 3))
                        .background(
                            gameViewModel.selectedTargetMove == move
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.85)
                        )
                        //.clipShape(Circle())
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                // Disable if gameViewModel says so, OR if no remote user is present
                .disabled(gameViewModel.areMoveSelectionButtonsDisabled || !rtcViewModel.hasRemoteUser)
                // Adjust opacity based on game state OR remote user presence
                .opacity(
                    (gameViewModel.areMoveSelectionButtonsDisabled && gameViewModel.selectedTargetMove != move) || !rtcViewModel.hasRemoteUser
                    ? 0.45
                    : 1
                )
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width - 24)
    }
    
    private func setupViewModels() {
        Task {
            isLoading = true
            rtcViewModel.onAppear(remoteView: remoteUIView)
            try await Task.sleep(nanoseconds: 50_000_000) // 0.5sec
            gameViewModel.onAppear()
            isLoading = false
        }
        // Set up network message handler to receive Player1's move
        rtcViewModel.onGameMessageReceived = { message in
            // In BvsP1View, we receive the Player1's move back
            // Determine the game result using the remote player's move
            print("Received Player1's move: \(message.remoteP2Move, default: "unknown")")
            
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
            DispatchQueue.main.async {
                gameViewModel.updateResultFromNetwork(
                    player2Move: outcome.playerTwoMove,
                    resultText: outcome.resultText
                )
            }
        }
    }
}

#Preview {
    let previewRtcViewModel = AgoraViewModel(channelName: "preview-room")
    previewRtcViewModel.remotePlayerName = "Preview Player"
    previewRtcViewModel.hasRemoteUser = true

    return BvsP1View(roomName: "preview-room", rtcViewModel: previewRtcViewModel)
}
