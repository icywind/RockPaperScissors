//
//  BvsP1View.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/21/26.
//

import SwiftUI

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
        let rtcVM = AgoraViewModel(channelName: roomName)               // 1. create rtcVM first with roomName
        _rtcViewModel = StateObject(wrappedValue: rtcVM)                // 2. give it to the view
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .human, rtcViewModel: rtcVM)) // 3. share the SAME instance
    }

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                // Room Name Label
                Text("Room: \(roomName)")
                    .font(.headline)
                    .foregroundStyle(Color.yellow)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                
                Player2ContainerView(
                    player2Name: "Player 1",
                    player2Description: "Remote user",
                    subView:
                            // Remote video view
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
            Task {
                isLoading = true
                rtcViewModel.onAppear(remoteView: remoteUIView)
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
    BvsP1View(roomName: "preview-room")
}
