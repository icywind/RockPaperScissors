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
    @Published private(set) var message: String = "Hello, World!"
    @Published private(set) var isJoined: Bool = false
    @Published private(set) var isEngineCreated: Bool = false
    @Published private(set) var hasRemoteUser: Bool = false

    private let rtcController = AgoraRtcController.shared
    private var channelName: String
    
    // Callback for handling received NetworkMessage
    var onNetworkMessageReceived: ((NetworkMessage) -> Void)? {
        didSet {
            rtcController.onNetworkMessageReceived = onNetworkMessageReceived
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
    
    func sendMessage(message: NetworkMessage) {
        rtcController.sendMessage(message: message)
    }
}

