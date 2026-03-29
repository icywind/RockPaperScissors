//
//  P1vsP2View.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct P1vsBView: View {
    let roomName: String
    @StateObject private var rtcViewModel: AgoraViewModel
    @StateObject private var gameViewModel: GameViewModel
    @State private var showTextEffect = false
    @State private var isLoading = true
    
    @State private var remoteUIView = UIView()
    
    // MARK: - struct init
    init(roomName: String) {
        self.roomName = roomName
        let rtcVM = AgoraViewModel(channelName: roomName)
        _rtcViewModel = StateObject(wrappedValue: rtcVM)
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .human, player2Type: .buttonpusher, rtcViewModel: rtcVM))
    }
    
    // MARK: - View body
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                PlayerCameraAreaView(
                    viewModel: gameViewModel.playerCameraViewModel,
                    player1Outcome: gameViewModel.player1Outcome
                )
                
                //ResultBoxView(resultText: gameViewModel.resultText)
                ResultBoxView(resultText: "\(gameViewModel.isShuffling ? "Shuffling..." : "Waiting for Player 2")")
                // ResultBoxView(resultText: "\(rtcViewModel.message)")

                Player2ContainerView(
                    player2Name: "Player 2",
                    player2Description: "Remote user",
                    subView:
                        HStack(spacing: 6) {
                            VideoContainerView(uiView: remoteUIView)
                                .background(Color.white)
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity)
                                .frame(height: UIScreen.main.bounds.height < 800 ? 120 : 220)
                            
                            AIPlayerAreaView(
                                move: gameViewModel.player2Move,
                                isShuffling: gameViewModel.isShuffling,
                                shufflingMove: gameViewModel.shufflingMove
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height < 800 ? 120 : 220)
                        }
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(.systemGroupedBackground))
            
            TextEffectView(showText:gameViewModel.player1Outcome?.rawValue ?? "",
                           isShowing: showTextEffect) {
                showTextEffect = false
                gameViewModel.resetPlayer1Outcome()
            }
        }
        .onAppear {
            Task {
                isLoading = true
                rtcViewModel.onAppear(remoteView: remoteUIView)
                try await Task.sleep(nanoseconds: 100_000_000) // 1 sec
                gameViewModel.onAppear()
                isLoading = false
            }
            // Set up network message handler
            rtcViewModel.onNetworkMessageReceived = { message in
                // Handle the network message from Player2
                // This will start shuffling in AIPlayerAreaView
                gameViewModel.handleNetworkMessage(message)
            }
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
        .onChange(of: rtcViewModel.hasRemoteUser) { newValue in
            if !newValue {
                // user gone offline
                print("Restarting camera ..... ")
                gameViewModel.playerCameraViewModel.restartSession()
            }
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
}

#Preview {
    P1vsBView(roomName: "preview-room")
}
