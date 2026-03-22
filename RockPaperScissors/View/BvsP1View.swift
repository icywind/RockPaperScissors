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
        let rtcVM = AgoraViewModel(channelName: roomName)
        _rtcViewModel = StateObject(wrappedValue: rtcVM)
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .human, rtcViewModel: rtcVM))
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