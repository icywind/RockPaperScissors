//
//  P1vsAIView.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/8/26.
//

import SwiftUI

struct P1vsAIView: View {
    let roomName: String
    @StateObject private var gameViewModel: GameViewModel
    @StateObject private var settings = Settings.shared
    @State private var showTieEffect = false
    @State private var showSettings = false
    
    init(roomName: String) {
        self.roomName = roomName
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .human))
    }

    var body: some View {
        NavigationStack {
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
                    .onTapGesture {
                        if settings.isAutoMode && !gameViewModel.areMoveSelectionButtonsDisabled {
                            let randomMove = HandMove.allCases.randomElement()!
                            gameViewModel.startGame(with: randomMove)
                        }
                    }

                    if !settings.isAutoMode {
                        HStack(spacing: 12) {
                            ForEach(HandMove.allCases, id: \.rawValue) { move in
                                Button(action: {
                                    gameViewModel.startGame(with: move)
                                }) {
                                    Image(imageName(for: move))
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Room: \(roomName)")
                        .font(.subheadline)
                        .foregroundStyle(Color.yellow)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: settings.isSoundEnabled) { newValue in
                gameViewModel.updateSoundSetting(newValue)
            }
        }
    }
}

private func imageName(for move: HandMove) -> String {
    switch move {
    case .rock:
        return "rock"
    case .paper:
        return "paper"
    case .scissors:
        return "scissors"
    }
}

#Preview {
    P1vsAIView(roomName: "preview-room")
}
