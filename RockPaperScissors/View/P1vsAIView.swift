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
    @State private var showTextEffect = false
    @State private var showSettings = false
    
    init(roomName: String) {
        self.roomName = roomName
        _gameViewModel = StateObject(wrappedValue: GameViewModel(player1Type: .human, player2Type: .computer))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
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
                .frame(maxWidth: .infinity)
                .frame(height: UIScreen.main.bounds.height < 800 ? 120 : 220)
                .onTapGesture {
                    if settings.isAutoMode && !gameViewModel.areMoveSelectionButtonsDisabled {
                        let randomMove = HandMove.allCases.randomElement()!
                        gameViewModel.startGame(with: randomMove)
                    }
                }

                if !settings.isAutoMode {
                    handMoveButtonsView()
                }
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
            gameViewModel.onAppear()
        }
        .onDisappear(perform: gameViewModel.onDisappear)
        .onChange(of: gameViewModel.player1Outcome) { newValue in
            if let _ = newValue {
                showTextEffect = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Room: \(roomName)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.yellow)
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
    
    // MARK: - Helper Functions
    
    private func handMoveButtonsView() -> some View {
        HStack(spacing: 8) {
            ForEach(HandMove.allCases, id: \.rawValue) { move in
                Button(action: {
                    gameViewModel.startGame(with: move)
                }) {
                    Image(imageName(for: move))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
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
