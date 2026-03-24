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
    @State private var showTieEffect = false
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
        NavigationStack {
            ZStack {
                VStack(spacing: 18) {
                    PlayerCameraAreaView(
                        viewModel: gameViewModel.playerCameraViewModel,
                        player1Outcome: gameViewModel.player1Outcome
                    )
                    
                    ResultBoxView(resultText: gameViewModel.resultText)
                    
                    Player2ContainerView(
                        player2Name: "Player 2",
                        player2Description: "Remote user",
                        subView:
                            HStack(spacing: 10) {
                                VideoContainerView(uiView: remoteUIView)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 220)
                                
                                AIPlayerAreaView(
                                    move: gameViewModel.player2Move,
                                    isShuffling: gameViewModel.isShuffling,
                                    shufflingMove: gameViewModel.shufflingMove
                                )
                            }
                    )
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(.systemGroupedBackground))
                
                TextEffectView(showText:gameViewModel.player1Outcome?.rawValue ?? "", 
                    isShowing: showTieEffect) {
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

#Preview {
    P1vsBView(roomName: "preview-room")
}
