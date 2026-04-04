//
//  AgoraRtcViewModel.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//  Refactored by BLACKBOXAI
//

import Foundation
import Combine
import AgoraRtcKit

class AgoraViewModel: ObservableObject {
    @Published var message: String = "Hello, World!"
    @Published var isJoined: Bool = false
    @Published var isEngineCreated: Bool = false
    @Published var hasRemoteUser: Bool = false
    @Published var remotePlayerName: String?

    private let rtcController = AgoraRtcController.shared
    private var channelName: String
    
    // Callback for handling received GameMessage
    var onGameMessageReceived: ((GameMessage) -> Void)? {
        didSet {
            rtcController.onGameMessageReceived = onGameMessageReceived
        }
    }
    
    init(channelName: String) {
        self.channelName = channelName
        rtcController.channelName = channelName // Configure controller
        bindController()
    }
    
    private func bindController() {
        // Bind controller's published properties
        rtcController.$message
            .assign(to: &$message)
        rtcController.$isJoined
            .assign(to: &$isJoined)
        rtcController.$isEngineCreated
            .assign(to: &$isEngineCreated)
        rtcController.$hasRemoteUser.assign(to: &$hasRemoteUser)
        rtcController.$remotePlayerName.assign(to: &$remotePlayerName)
    }
    
    func onAppear(remoteView: VideoUIView?) {
        rtcController.onAppear(remoteView: remoteView)
    }
    
    func destroy() {
        rtcController.destroy()
    }
    
    func pushVideoFrame(pixelBuffer: CVPixelBuffer) {
        rtcController.pushVideoFrame(pixelBuffer: pixelBuffer)
    }
    
    func sendMessage(message: GameMessage) {
        rtcController.sendMessage(message: message)
    }
    
    func sendNameMessage(playerName: String) {
        rtcController.sendNameMessage(playerName: playerName)
    }
}
