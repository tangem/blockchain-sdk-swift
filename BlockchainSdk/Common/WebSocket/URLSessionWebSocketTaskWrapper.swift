//
//  URLSessionWebSocketTaskWrapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A wrapper to work with `URLSessionWebSocketTask` through async/await method
class URLSessionWebSocketTaskWrapper {
    private let url: URL
    
    private var webSocketTaskDidOpen: CheckedContinuation<Void, Never>?
    private var webSocketTaskDidClose: CheckedContinuation<URLSessionWebSocketTask.CloseCode, Never>?
    private var session: URLSession?
    private var _sessionWebSocketTask: URLSessionWebSocketTask?

    private var sessionWebSocketTask: URLSessionWebSocketTask {
        get throws {
            guard let _sessionWebSocketTask else {
                throw WebSocketTaskError.webSocketNotFound
            }
            
            return _sessionWebSocketTask
        }
    }
    
    init(url: URL) {
        self.url = url
    }
    
    deinit {
        // We have to disconnect here that release all objects
        cancel()
    }
    
    func sendPing() async throws {
        let socketTask = try sessionWebSocketTask

        return try await withCheckedThrowingContinuation { [weak socketTask] continuation in
            socketTask?.sendPing { error in
                switch error {
                case .none:
                    continuation.resume()
                case .some(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func send(message: URLSessionWebSocketTask.Message) async throws {
        try await sessionWebSocketTask.send(message)
    }
    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        return try await sessionWebSocketTask.receive()
    }
    
    func connect() async {
        // The delegate will be kept by URLSession
        let delegate = URLSessionWebSocketDelegateWrapper(
            webSocketTaskDidOpen: { [weak self] task in
                self?.webSocketTaskDidOpen?.resume()
            },
            webSocketTaskDidClose: { [weak self] task, closeCode in
                self?.webSocketTaskDidClose?.resume(returning: closeCode)
            }, webSocketTaskDidCompleteWithError: { [weak self] _, _ in
                self?.cancel()
            }
        )
        
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        _sessionWebSocketTask = session?.webSocketTask(with: url)
        _sessionWebSocketTask?.resume()

        return await withCheckedContinuation { [weak self] continuation in
            self?.webSocketTaskDidOpen = continuation
        }
    }
    
    func cancel() {
        _sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        // Important for release of the session's delegate
        session?.invalidateAndCancel()
    }
    
    func cancel() async -> URLSessionWebSocketTask.CloseCode {
        _sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        
        return await withCheckedContinuation { [weak self] continuation in
            self?.webSocketTaskDidClose = continuation
        }
    }
}

// MARK: - CustomStringConvertible

extension URLSessionWebSocketTaskWrapper: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Error

enum WebSocketTaskError: Error {
    case webSocketNotFound
}
