//
//  WebSocketTask.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

/// A wrapper to work with `URLSessionWebSocketTask` through async/await method
class WebSocketTask {
    private let url: URL
    private let delegateQueue: OperationQueue
    private lazy var delegate: URLSessionWebSocketDelegateWrapper = {
        .init(
            webSocketTaskDidOpen: { [weak self] task in
                self?.webSocketTaskDidOpen?.resume()
            },
            webSocketTaskDidClose: { [weak self] task, closeCode in
                self?.webSocketTaskDidClose?.resume(returning: closeCode)
            }
        )
    }()
    
    private var webSocketTaskDidOpen: CheckedContinuation<Void, Never>?
    private var webSocketTaskDidClose: CheckedContinuation<URLSessionWebSocketTask.CloseCode, Never>?
    private var sessionWebSocketTask: URLSessionWebSocketTask?
    
    init(
        url: URL,
        delegateQueue: OperationQueue = .init()
    ) {
        self.url = url
        self.delegateQueue = delegateQueue
        
        print("init \(Thread.current) \(self)")
    }
    
    deinit {
        print("deinit \(Thread.current) \(self)")
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
    
    func connect() async {
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue)
        sessionWebSocketTask = session.webSocketTask(with: url)
        sessionWebSocketTask?.resume()
        
        return await withCheckedContinuation { [weak self] continuation in
            self?.webSocketTaskDidOpen = continuation
        }
    }
    
    func disconnect() async -> URLSessionWebSocketTask.CloseCode {
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        
        return await withCheckedContinuation { [weak self] continuation in
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

extension WebSocketTask: CustomStringConvertible {
    var description: String {
        objectDescription(self)
    }
}

// MARK: - Error

enum WebSocketTaskError: Error {
    case webSocketNotFound
}

class URLSessionWebSocketDelegateWrapper: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTaskDidOpen: (URLSessionWebSocketTask) -> Void?
    private var webSocketTaskDidClose: (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    
    init(
        webSocketTaskDidOpen: @escaping (URLSessionWebSocketTask) -> Void?,
        webSocketTaskDidClose: @escaping (URLSessionWebSocketTask, URLSessionWebSocketTask.CloseCode) -> Void
    ) {
        self.webSocketTaskDidOpen = webSocketTaskDidOpen
        self.webSocketTaskDidClose = webSocketTaskDidClose
        
        print("init URLSessionWebSocketDelegateWrapper")
    }
    
    deinit {
        print("deinit URLSessionWebSocketDelegateWrapper")
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
