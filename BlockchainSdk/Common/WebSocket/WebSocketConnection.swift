//
//  WebSocketConnection.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor WebSocketConnection {
    private let url: URL
    private let ping: Ping
    private let timeout: TimeInterval
    
    private var _webSocketTask: WebSocketTask?
    private var pingTask: Task<Void, Error>?
    private var timeoutTask: Task<Void, Error>?
    
    private var dispatchSemaphore = DispatchSemaphore(value: 1)
    
    /// - Parameters:
    ///   - url: A `wss` URL
    ///   - ping: The value that will be sent after a certain interval in seconds
    ///   - timeout: The value in seconds through which the connection will be terminated, if there are no new `send` calls
    init(url: URL, ping: Ping, timeout: TimeInterval) {
        self.url = url
        self.ping = ping
        self.timeout = timeout
    }
    
    deinit {
        disconnect()
    }
    
    public func send(_ message: URLSessionWebSocketTask.Message) async throws -> Data {
        let webSocketTask = await webSocketTask()
        log("Send: \(message)")

        // Send a message
        try await webSocketTask.send(message: message)

        // Get a message from the last response
        let response = try await webSocketTask.receive()

        log("Receive: \(response)")
        let responseData = try mapToData(from: response)

        // Restart the disconnect timer
        startTimeoutTask()
        startPingTask()

        return responseData
    }
    
    public func disconnect() {
        pingTask?.cancel()

        _webSocketTask?.disconnect { _, closeCode in
            self.log("Connection did close with: \(closeCode)")
            self._webSocketTask = nil
        }
    }
}

// MARK: - Private

private extension WebSocketConnection {
    func startPingTask() {
        pingTask?.cancel()
        pingTask = Task { [weak self] in
            guard let self else { return }

            try await Task.sleep(nanoseconds: UInt64(ping.interval) * NSEC_PER_SEC)
            
            try Task.checkCancellation()
            
            try await ping()
        }
    }
    
    func startTimeoutTask() {
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            guard let self else { return }

            try await Task.sleep(nanoseconds: UInt64(timeout) * NSEC_PER_SEC)
            
            try Task.checkCancellation()
            
            await disconnect()
        }
    }
    
    func ping() async throws {
        switch ping {
        case .message(_, let message):
            log("Send ping: \(message)")
            
            try await _webSocketTask?.send(message: message)
            let response = try await _webSocketTask?.receive()
            log("Ping response \(String(describing: response))")

        case .plain:
            log("Send plain ping")
            
            try await _webSocketTask?.sendPing()
        }
        
        startPingTask()
    }
    
    func webSocketTask() async -> WebSocketTask {
        if let webSocketTask = _webSocketTask {
            return webSocketTask
        }
        
        _webSocketTask = WebSocketTask(url: url)
        let task = await withCheckedContinuation { continuation in
            _webSocketTask?.connect(webSocketTaskDidOpen: { webSocketTask in
                continuation.resume(returning: webSocketTask)
            })
        }
        log("WebSocketTask did open")
        return task
    }
    
    func mapToData(from message: URLSessionWebSocketTask.Message) throws -> Data {
        switch message {
        case .data(let data):
            return data
            
        case .string(let string):
            guard let data = string.data(using: .utf8) else {
                throw WebSocketConnectionError.invalidResponse
            }

            return data
            
        @unknown default:
            fatalError()
        }
    }
    
    func log(_ args: Any) {
        print("\(Date()) \(Thread.current) [\(self)]", args)
   }
}

// MARK: - Model

extension WebSocketConnection {
    enum Ping {
        case plain(interval: TimeInterval)
        case message(interval: TimeInterval, message: URLSessionWebSocketTask.Message)
        
        var interval: TimeInterval {
            switch self {
            case .plain(let interval):
                return interval
            case .message(let interval, _):
                return interval
            }
        }
    }
}

// MARK: - Error

enum WebSocketConnectionError: Error {
    case responseNotFound
    case invalidResponse
    case invalidRequest
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
