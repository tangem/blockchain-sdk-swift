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
                self?.webSocketTaskDidOpen?(task)
            },
            webSocketTaskDidClose: { [weak self] task, code in
                self?.webSocketTaskDidClose?(task, code)
            }
        )
    }()
    
    private var webSocketTaskDidOpen: ((URLSessionWebSocketTask) -> Void)? = nil
    private var webSocketTaskDidClose: ((URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void)? = nil

    private var sessionWebSocketTask: URLSessionWebSocketTask?
    
    nonisolated var description: String {
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
        Task { [weak self] in
            await self?.disconnect()
        }
    }
    
    func sendPing() async throws {
        guard let sessionWebSocketTask else {
            throw WebSocketTaskError.webSocketNotFound
        }

        return try await withCheckedThrowingContinuation { [weak self] continuation in
            self?.sessionWebSocketTask?.sendPing { error in
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

        print("\(self) Send: \(message) state: \(sessionWebSocketTask.state)")
        try await sessionWebSocketTask.send(message)
    }
    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        guard let sessionWebSocketTask else {
            throw WebSocketTaskError.webSocketNotFound
        }
        
        return try await sessionWebSocketTask.receive()
    }
    
    func connect(completion: ((URLSessionWebSocketTask) -> Void)?) {
        self.webSocketTaskDidOpen = completion
        
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue)
        sessionWebSocketTask = session.webSocketTask(with: url)
        sessionWebSocketTask?.resume()
    }
    
    func disconnect(completion: ((URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void)?) {
        self.webSocketTaskDidClose = completion
        
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
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
