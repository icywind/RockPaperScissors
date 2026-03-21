//
//  P1vsP2View.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import SwiftUI

struct P1vsP2View: View {
    @StateObject private var rtcViewModel = AgoraViewModel()
    @StateObject private var gameViewModel: GameViewModel
    @State private var showTieEffect = false
    @State private var isLoading = true
    
    @State private var remoteUIView = UIView()
    
    // MARK: - struct init
    init() {
        let rtcVM = AgoraViewModel()                                    // 1. create rtcVM first
        _rtcViewModel = StateObject(wrappedValue: rtcVM)                // 2. give it to the view
        _gameViewModel = StateObject(wrappedValue: GameViewModel(rtcViewModel: rtcVM)) // 3. share the SAME instance
    }

    /*
     SyntaxMeaning
        rtcViewModelThe unwrapped value (AgoraViewModel)
       _rtcViewModelThe underlying StateObject wrapper itself
     */
    
    // MARK: - View body
    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                PlayerCameraAreaView(
                    viewModel: gameViewModel.playerCameraViewModel,
                    player1Outcome: gameViewModel.player1Outcome
                )

                ResultBoxView(resultText: gameViewModel.resultText)

                HStack(spacing: 10) {
                    // Remote video view
                    VideoContainerView(uiView: remoteUIView)
                        .background(Color.black)
                        .cornerRadius(8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    
                    AIPlayerAreaView(
                        move: gameViewModel.player2Move,
                        isShuffling: gameViewModel.isShuffling,
                        shufflingMove: gameViewModel.shufflingMove
                    )
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
    P1vsP2View()
}
