//
//  WebSocketTask.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class URLSessionWebSocketDelegateWrapper: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTaskDidOpen: (URLSessionWebSocketTask) -> Void?
    private var webSocketTaskDidClose: (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    
    init(
        webSocketTaskDidOpen: @escaping (URLSessionWebSocketTask) -> Void?,
        webSocketTaskDidClose: @escaping (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    ) {
        self.webSocketTaskDidOpen = webSocketTaskDidOpen
        self.webSocketTaskDidClose = webSocketTaskDidClose
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        webSocketTaskDidOpen(webSocketTask)
    }
    
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        webSocketTaskDidClose(webSocketTask, closeCode)
    }
}

/// A wrapper to work with `URLSessionWebSocketTask` through async/await method
class WebSocketTask: CustomStringConvertible {
    private let url: URL
    private let delegateQueue: OperationQueue
    private lazy var delegate: URLSessionWebSocketDelegateWrapper = {
        .init(
            webSocketTaskDidOpen: { [weak self] task in
                guard let self else { return }

                self.webSocketTaskDidOpen?.resume(returning: self)
            },
            webSocketTaskDidClose: { [weak self] task, closeCode in
                guard let self else { return }

                self.webSocketTaskDidClose?.resume(returning: (self, closeCode))
            }
        )
    }()
    
    private var webSocketTaskDidOpen: UnsafeContinuation<WebSocketTask, Never>?
    private var webSocketTaskDidClose: UnsafeContinuation<(WebSocketTask, URLSessionWebSocketTask.CloseCode), Never>?

    private var sessionWebSocketTask: URLSessionWebSocketTask?
    
    var description: String {
        objectDescription(self)
    }
    
    init(
        url: URL,
        delegateQueue: OperationQueue = .init()
    ) {
        self.url = url
        self.delegateQueue = delegateQueue
        
        print("init \(self)")
    }
    
    deinit {
        print("deinit \(self)")
        Task { await disconnect() }
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
    
    func connect() async -> WebSocketTask {
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue)
        sessionWebSocketTask = session.webSocketTask(with: url)
        sessionWebSocketTask?.resume()
        
        return await withUnsafeContinuation { [weak self] continuation in
            self?.webSocketTaskDidOpen = continuation
        }
    }
    
    func disconnect() async -> (WebSocketTask, URLSessionWebSocketTask.CloseCode) {
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        
        return await withUnsafeContinuation { [weak self] continuation in
            self?.webSocketTaskDidClose = continuation
        }
    }

    /*
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
     */
}

// MARK: - Error

enum WebSocketTaskError: Error {
    case webSocketNotFound
}
