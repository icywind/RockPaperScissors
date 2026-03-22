//
//  TokenService.swift
//  RockPaperScissors
//
//  Created by Rick Cheng on 3/20/26.
//

import Foundation

// MARK: - Models
enum RtcRole: String, Codable {
    case broadcaster = "broadcaster"
    case subscriber  = "subscriber"
}

enum TokenType: String, Codable {
    case rtc = "rtc"
    case rtm = "rtm"
    case chat = "chat"
}

struct TokenRequest: Encodable {
    let tokenType: TokenType
    let channel: String
    let role: RtcRole
    let uid: String
    let expire: Int
}

struct TokenResponse: Decodable, Sendable {
    let token: String
}

// MARK: - Error Types

enum TokenServiceError: LocalizedError {
    case invalidURL
    case encodingFailed
    case noData
    case decodingFailed(Error)
    case httpError(statusCode: Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL"
        case .encodingFailed:       return "Failed to encode request body"
        case .noData:               return "No data received from server"
        case .decodingFailed(let e): return "Decoding failed: \(e.localizedDescription)"
        case .httpError(let code):  return "HTTP error with status code: \(code)"
        case .networkError(let e):  return "Network error: \(e.localizedDescription)"
        }
    }
}

// MARK: - Token Service

final class TokenService {

    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession

    // MARK: Init

    init(
        baseURL: String ,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: Public API
    
    // MARK: - Async/await version of fetchToken.
    @available(iOS 15.0, macOS 12.0, *)
    func fetchRTCToken(
        uid: String,
        channel: String,
        expire: Int = 3600
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/getToken") else {
            throw TokenServiceError.invalidURL
        }

        let requestBody = TokenRequest(
            tokenType: .rtc,
            channel: channel,
            role: .broadcaster,
            uid: uid,
            expire: expire)
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            throw TokenServiceError.encodingFailed
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw TokenServiceError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            return tokenResponse.token
        } catch {
            throw TokenServiceError.decodingFailed(error)
        }
    }

    // MARK: - Callback version
    
    /// Fetches a token from the server.
    /// - Parameters:
    ///   - tokenType: The type of token to request (e.g. "chat")
    ///   - uid: The user identifier (e.g. "unity")
    ///   - expire: Token expiry duration in seconds (e.g. 3600)
    ///   - completion: Called on the main thread with the result
    func fetchRTCToken(
        uid: String,
        channel: String,
        expire: Int = 3600,
        completion: @escaping (Result<String, TokenServiceError>) -> Void
    ) {
        // Build URL
        guard let url = URL(string: "\(baseURL)/getToken") else {
            completion(.failure(.invalidURL))
            return
        }

        // Build request body
        let requestBody = TokenRequest(tokenType: .rtc,
                                       channel: channel,
                                       role:.broadcaster,
                                       uid: uid, expire: expire)
        
        guard let httpBody = try? JSONEncoder().encode(requestBody) else {
            completion(.failure(.encodingFailed))
            return
        }

        // Configure URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        // Execute request
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                Self.complete(completion, with: .failure(.networkError(error)))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                Self.complete(completion, with: .failure(.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            guard let data = data else {
                Self.complete(completion, with: .failure(.noData))
                return
            }

            do {
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                Self.complete(completion, with: .success(tokenResponse.token))
            } catch {
                Self.complete(completion, with: .failure(.decodingFailed(error)))
            }
        }.resume()
    }

    // MARK: Helpers

    private static func complete<T>(
        _ completion: @escaping (Result<T, TokenServiceError>) -> Void,
        with result: Result<T, TokenServiceError>
    ) {
        DispatchQueue.main.async { completion(result) }
    }
}
