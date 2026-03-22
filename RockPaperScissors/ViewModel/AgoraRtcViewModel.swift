//
//  Agora.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import Foundation
import Combine
import AgoraRtcKit

typealias VideoUIView = UIView

class AgoraViewModel : NSObject, ObservableObject {
    @Published
    var message: String = "Hello, World!"
    
    @Published
    var isJoined: Bool = false
    
    @Published
    var isEngineCreated: Bool = false
    
    private var agoraKit: AgoraRtcEngineKit!
    
    private var remoteView: VideoUIView?
    
    private var channelName: String
    
    init(channelName: String) {
        self.channelName = channelName.isEmpty ? "rockgame" : channelName
        super.init()
    }
    
    override init() {
        self.channelName = "rockgame"
        super.init()
    }
    
    func onAppear(remoteView : UIView?) {
        let appId = "3df5beb6c72340639f5b214c59f763c6"
        let configs: [String: Any] = [
            "channelName": channelName,
            "tokenServerURL":"https://agora-token-server-lz2y.onrender.com"
        ]
        setupRTC(appId: appId, configs: configs, remoteView:remoteView)
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
        // Configuring Privatization Parameters
        // Util.configPrivatization(agoraKit: agoraKit)
        
        // agoraKit.setLogFile(LogUtils.sdkLogPath())
        
        // get channel name from configs
        guard let channelName = configs["channelName"] as? String else {return}
        //let fps = GlobalSettings.shared.getFps()
        //let resolution = GlobalSettings.shared.getResolution()
        //let orientation = GlobalSettings.shared.getOrientation()
        
        // make myself a broadcaster
        agoraKit.setClientRole(.broadcaster)
        // enable video module and set up video encoding configs
        agoraKit.enableVideo()
        agoraKit.enableAudio()
        
        // Enable external video source for pushing custom frames
        agoraKit.setExternalVideoSource(true, useTexture: false, sourceType: .videoFrame)
        /*
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: resolution,
                                                                             frameRate: fps,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: orientation, mirrorMode: .auto))
         */
        
        
        // Set audio route to speaker
        agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        
        // start joining channel
        // 1. Users can only see each other after they join the
        // same channel successfully using the same app id.
        // 2. If app certificate is turned on at dashboard, token is needed
        // when joining channel. The channel name and uid used to calculate
        // the token has to match the ones used for channel join
        let option = AgoraRtcChannelMediaOptions()
        option.publishCameraTrack = true
        option.publishMicrophoneTrack = true
        option.autoSubscribeVideo = true
        option.clientRoleType = .broadcaster
        
        isEngineCreated = true
        
        let tokenService = TokenService(baseURL:(configs["tokenServerURL"] as? String)!)
        // — Async/await style (iOS 15+ / macOS 12+) —
        Task {
            do {
                let token = try await tokenService.fetchRTCToken(
                    uid: "0", channel: channelName
                )
                print("Token: \(token)")
                let result = self.agoraKit.joinChannel(byToken: token, channelId: channelName, uid: 0, mediaOptions: option)
                if result != 0 {
                    message = "Join channel failed: \(result)"
                    print(message)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
    
    func onDestory() {
        agoraKit.disableAudio()
        agoraKit.disableVideo()
        if isJoined {
            agoraKit.stopPreview()
            agoraKit.leaveChannel { (stats) -> Void in
                print ("left channel, duration: \(stats.duration)")
            }
        }
        AgoraRtcEngineKit.destroy()
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
}

// MARK: - Delegates for RTC Engine events

extension AgoraViewModel : AgoraRtcEngineDelegate {
    /// callback when warning occured for agora sdk, warning can usually be ignored, still it's nice to check out
    /// what is happening
    /// Warning code description can be found at:
    /// en: https://api-ref.agora.io/en/voice-sdk/ios/3.x/Constants/AgoraWarningCode.html
    /// cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraWarningCode.html
    /// @param warningCode warning code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        message = ( "warning: \(String(describing: warningCode))")
        print(message)
    }
    
    /// callback when error occured for agora sdk, you are recommended to display the error descriptions on demand
    /// to let user know something wrong is happening
    /// Error code description can be found at:
    /// en: https://api-ref.agora.io/en/video-sdk/ios/4.x/documentation/agorartckit/agoraerrorcode
    /// cn: https://doc.shengwang.cn/api-ref/rtc/ios/error-code
    /// @param errorCode error code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        message = ( "error: \(String(describing: errorCode))" )
        print(message)
//        self.showAlert(title: "Error", message: "Error \(errorCode.description) occur")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.isJoined = true
        print ("Join [\(channel)] with uid \(uid) elapsed \(elapsed)ms")
    }
    
    /// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        message = ("remote user join: \(uid) \(elapsed)ms")
        print(message)
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = remoteView
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    /// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param reason reason why this user left, note this event may be triggered when the remote user
    /// become an audience in live broadcasting profile
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        message = ("remote user left: \(uid) reason \(reason)")
        print(message)
        
        // to unlink your view from sdk, so that your view reference will be released
        // note the video will stay at its last frame, to completely remove it
        // you will need to remove the EAGL sublayer from your binded view
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
}
