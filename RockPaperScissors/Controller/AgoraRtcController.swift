//
//  AgoraRtcController.swift
//  RockPaperScissors
//
//  Created by BLACKBOXAI
//

import Foundation
import Combine
import AgoraRtcKit

typealias VideoUIView = UIView

final class AgoraRtcController: NSObject, AgoraRtcEngineDelegate {
    static let shared = AgoraRtcController()
    
    @Published var message: String = "Hello, World!"
    @Published var isJoined: Bool = false
    @Published var isEngineCreated: Bool = false
    @Published var hasRemoteUser: Bool = false
    
    private var agoraKit: AgoraRtcEngineKit!
    private var remoteView: VideoUIView?
    public var channelName: String
    private var activeRemoteUserUid: UInt? = nil
    private var streamId: Int = 0
    
    var simulatorVideoTimer: Timer?
    
    // Callback for handling received NetworkMessage
    var onNetworkMessageReceived: ((NetworkMessage) -> Void)?
    
    private init(channelName: String = "rockgame") {
        self.channelName = channelName
    }
    
    private override init() {
        self.channelName = "rockgame"
        super.init()
    }
    
    func onAppear(remoteView: VideoUIView?) {
        let appId = "3df5beb6c72340639f5b214c59f763c6"
        let configs: [String: Any] = [
            "channelName": channelName,
            "tokenServerURL": "https://agora-token-server-lz2y.onrender.com"
        ]
        setupRTC(appId: appId, configs: configs, remoteView: remoteView)
        
        // Start simulator video if running on simulator
#if targetEnvironment(simulator)
        startSimulatorVideo()
#endif
    }
    
    func setupRTC(appId: String,
                  configs: [String: Any],
                  remoteView: VideoUIView?) {
        self.remoteView = remoteView
        // set up agora instance when view loaded
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.areaCode = .global
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // make myself a broadcaster
        agoraKit.setClientRole(.broadcaster)
        // enable video module and set up video encoding configs
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        
        // Enable external video source for pushing custom frames
        agoraKit.setExternalVideoSource(true, useTexture: false, sourceType: .videoFrame)
        
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // get channel name from configs
        guard let channelName = configs["channelName"] as? String else { return }
        
        let option = AgoraRtcChannelMediaOptions()
        option.publishCameraTrack = true
        option.publishMicrophoneTrack = true
        option.autoSubscribeVideo = true
        option.clientRoleType = .broadcaster
        
        isEngineCreated = true
        
        let tokenService = TokenService(baseURL: (configs["tokenServerURL"] as? String)!)
        // Async/await style
        Task {
            do {
                let token = try await tokenService.fetchRTCToken(
                    uid: "0", channel: channelName
                )
                print("Token: \(token)")
                let result = self.agoraKit.joinChannel(byToken: token, channelId: channelName, uid: 0, mediaOptions: option)
                if result != 0 {
                    self.message = "Join channel failed: \(result)"
                    print(self.message)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func destroy() {
#if targetEnvironment(simulator)
        stopSimulatorVideo()
#endif
        
        agoraKit.disableAudio()
        agoraKit.disableVideo()
        if isJoined {
            agoraKit.stopPreview()
            agoraKit.leaveChannel { stats in
                print("left channel, duration: \(stats.duration)")
            }
            isJoined = false
        }
        AgoraRtcEngineKit.destroy()
        print("Agora engine destroyed!")
    }
    
    func pushVideoFrame(pixelBuffer: CVPixelBuffer) {
        guard isJoined, isEngineCreated else { return }
        
        let videoFrame = AgoraVideoFrame()
        videoFrame.format = 12 // kCVPixelFormatType_32BGRA
        videoFrame.textureBuf = pixelBuffer
        videoFrame.time = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 1000)
        videoFrame.rotation = 0
        
        agoraKit.pushExternalVideoFrame(videoFrame, videoTrackId: 0)
    }
    
    func sendMessage(message: NetworkMessage) {
        let encoder = JSONEncoder()
        let json = try? encoder.encode(message)
        guard let json else { return }
        
        var result: Int32 = 0
        if streamId == 0 {
            result = agoraKit.createDataStream(&streamId, reliable: true, ordered: true)
            if result != 0 {
                print("create data stream failed, error: \(result)")
            }
        } else {
            print("datastream id:", streamId)
        }
        
        let sendResult = agoraKit.sendStreamMessage(streamId, data: json)
        if sendResult != 0 {
            print("send message failed, error = \(sendResult)")
        }
    }
    
    func sendMessage(message: String) {
        var result: Int32 = 0
        if streamId == 0 {
            result = agoraKit.createDataStream(&streamId, reliable: true, ordered: true)
            if result != 0 {
                print("create data stream failed, error: \(result)")
            }
        }
        
        let sendResult = agoraKit.sendStreamMessage(streamId, data: Data(message.utf8))
        if sendResult != 0 {
            print("send message failed, error: \(sendResult)")
        }
    }
    
    // MARK: - Delegates for RTC Engine events
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        message = "warning: \(String(describing: warningCode))"
        print(message)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        message = "error: \(String(describing: errorCode))"
        print(message)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        isJoined = true
        print("Join [\(channel)] with uid \(uid) elapsed \(elapsed)ms")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        message = String(format: "remote user join: \(uid) \(elapsed)ms active:%d\n", activeRemoteUserUid ?? 0)
        if let existingUid = activeRemoteUserUid, existingUid != uid {
            message = "dropped user \(uid), remote user \(existingUid) is still active"
            print(message)
            return
        }
        
        activeRemoteUserUid = uid
        print(message)
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteView
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        hasRemoteUser = true
        sendMessage(message: "Hello \(uid)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        message = "remote user left: \(uid) reason \(reason)"
        print(message)
        
        if activeRemoteUserUid == uid {
            activeRemoteUserUid = nil
            hasRemoteUser = false
        }
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
        
        streamId = 0
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, receiveStreamMessageFromUid uid: UInt, streamId: Int, data: Data) {
        let text = String.init(data: data, encoding: .utf8) ?? ""
        message = "receiveStreamMessageFromUid: \(uid) \(text)"
        print(message)
        
        if uid == activeRemoteUserUid {
            if let msg = try? JSONDecoder().decode(NetworkMessage.self, from: data) {
                print("msg.move: \(msg.remoteP2Move)")
                onNetworkMessageReceived?(msg)
            }
        }
    }
}

