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
    private let delegateQueue: OperationQueue
    
    private var webSocketTaskDidOpen: CheckedContinuation<Void, Never>?
    private var webSocketTaskDidClose: CheckedContinuation<URLSessionWebSocketTask.CloseCode, Never>?
    private var session: URLSession?
    private var sessionWebSocketTask: URLSessionWebSocketTask?
    
    init(
        url: URL,
        delegateQueue: OperationQueue = .init()
    ) {
        self.url = url
        self.delegateQueue = delegateQueue
    }
    
    deinit {
        // We have to disconnect here that release all objects
        cancel()
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
        // The delegate will be kept by URLSession
        let delegate = URLSessionWebSocketDelegateWrapper(
            webSocketTaskDidOpen: { [weak self] task in
                self?.webSocketTaskDidOpen?.resume()
            },
            webSocketTaskDidClose: { [weak self] task, closeCode in
                self?.webSocketTaskDidClose?.resume(returning: closeCode)
            }
        )
        
        session = URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue)
        sessionWebSocketTask = session?.webSocketTask(with: url)
        sessionWebSocketTask?.resume()

        return await withCheckedContinuation { [weak self] continuation in
            self?.webSocketTaskDidOpen = continuation
        }
    }
    
    func cancel() {
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        // Important for release of the session's delegate
        session?.invalidateAndCancel()
    }
    
    func cancel() async -> URLSessionWebSocketTask.CloseCode {
        sessionWebSocketTask?.cancel(with: .goingAway, reason: nil)
        
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

// MARK: - URLSessionTask.State + CustomStringConvertible

extension URLSessionTask.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .running:
            return "URLSessionTask.State.running"
        case .suspended:
            return "URLSessionTask.State.suspended"
        case .canceling:
            return "URLSessionTask.State.canceling"
        case .completed:
            return "URLSessionTask.State.completed"
        @unknown default:
            return "URLSessionTask.State.@unknowndefault"
        }
    }
}

// MARK: - URLSessionTask.Message + CustomStringConvertible

extension URLSessionWebSocketTask.Message: CustomStringConvertible {
    public var description: String {
        switch self {
        case .data(let data):
            return "URLSessionWebSocketTask.Message.data: \(data)"
        case .string(let string):
            return "URLSessionWebSocketTask.Message.string: \(string)"
        @unknown default:
            return "URLSessionWebSocketTask.Message.@unknowndefault"
        }
    }
}

// MARK: - URLSessionTask.CloseCode + CustomStringConvertible

extension URLSessionWebSocketTask.CloseCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "URLSessionWebSocketTask.CloseCode.invalid"
        case .normalClosure:
            return "URLSessionWebSocketTask.CloseCode.normalClosure"
        case .goingAway:
            return "URLSessionWebSocketTask.CloseCode.goingAway"
        case .protocolError:
            return "URLSessionWebSocketTask.CloseCode.protocolError"
        case .unsupportedData:
            return "URLSessionWebSocketTask.CloseCode.unsupportedData"
        case .noStatusReceived:
            return "URLSessionWebSocketTask.CloseCode.noStatusReceived"
        case .abnormalClosure:
            return "URLSessionWebSocketTask.CloseCode.abnormalClosure"
        case .invalidFramePayloadData:
            return "URLSessionWebSocketTask.CloseCode.invalidFramePayloadData"
        case .policyViolation:
            return "URLSessionWebSocketTask.CloseCode.policyViolation"
        case .messageTooBig:
            return "URLSessionWebSocketTask.CloseCode.messageTooBig"
        case .mandatoryExtensionMissing:
            return "URLSessionWebSocketTask.CloseCode.mandatoryExtensionMissing"
        case .internalServerError:
            return "URLSessionWebSocketTask.CloseCode.internalServerError"
        case .tlsHandshakeFailure:
            return "URLSessionWebSocketTask.CloseCode.tlsHandshakeFailure"
        @unknown default:
            return "URLSessionWebSocketTask.CloseCode.@unknowndefault"
        }
    }
}

