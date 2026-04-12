import Foundation

enum Secrets {
    private static func value(for key: String) -> String? {
        return Bundle.main.object(forInfoDictionaryKey: key) as? String
    }

    static var agoraAppId: String {
        guard let appId = value(for: "AgoraAppID"), !appId.isEmpty else {
            fatalError("Could not find Agora App ID in Secrets.xcconfig. Make sure it's set up correctly.")
        }
        return appId
    }

    static var tokenServerURL: String {
        guard let url = value(for: "AgoraTokenServerURL"), !url.isEmpty else {
            fatalError("Could not find Agora Token Server URL Secrets.xcconfig. Make sure it's set up correctly.")
        }
        return url
    }
}
