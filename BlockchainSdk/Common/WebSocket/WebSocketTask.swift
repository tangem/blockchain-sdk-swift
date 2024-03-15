//
//  WebSocketTask.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A wrapper to work with `URLSessionWebSocketTask` through async/await method
class WebSocketTask: NSObject, URLSessionWebSocketDelegate {
    private let url: URL
    private let delegateQueue: OperationQueue

    private var webSocketTaskDidOpen: ((WebSocketTask) -> Void)?
    private var webSocketTaskDidClose: ((WebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void)?
    private var sessionWebSocketTask: URLSessionWebSocketTask?
    
    init(
        url: URL,
        delegateQueue: OperationQueue = .init()
    ) {
        self.url = url
        self.delegateQueue = delegateQueue
    }
    
    deinit {
        disconnect()
    }
    
    func sendPing() async throws {
        guard let sessionWebSocketTask else {
            throw WebSocketTaskError.webSocketNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            sessionWebSocketTask.sendPing { error in
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
        guard let sessionWebSocketTask else {
            throw WebSocketTaskError.webSocketNotFound
        }

        try await sessionWebSocketTask.send(message)
    }
    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        guard let sessionWebSocketTask else {
            throw WebSocketTaskError.webSocketNotFound
        }
        
        return try await sessionWebSocketTask.receive()
    }
    
    func connect(webSocketTaskDidOpen: ((WebSocketTask) -> Void)? = nil) {
        self.webSocketTaskDidOpen = webSocketTaskDidOpen

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        sessionWebSocketTask = session.webSocketTask(with: url)
        sessionWebSocketTask?.resume()
    }
    
    func disconnect(webSocketTaskDidClose: ((WebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void)? = nil) {
        self.webSocketTaskDidClose = webSocketTaskDidClose
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        webSocketTaskDidOpen?(self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        webSocketTaskDidClose?(self, closeCode)
    }
}
// MARK: - Error

enum WebSocketTaskError: Error {
    case webSocketNotFound
}
