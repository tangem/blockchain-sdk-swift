//
//  WebSocketConnection.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public class WebSocketConnection: NSObject {
    private let url: URL
    private let delegateQueue: OperationQueue
    private let ping: Ping
    
    private var webSocket: URLSessionWebSocketTask?
    private var pingTask: Task<Void, Never>?
    
    
    
    public init(url: URL, ping: Ping) {
        self.url = url
        self.ping = ping
        self.delegateQueue = .init()
        
        super.init()

        makeWebSocketTask()
        connect()
    }
    
    deinit {
        disconnect()
    }
    
    public func send<Message: Encodable>(_ message: Message, encoder: JSONEncoder = .init()) async throws -> Data {
        guard let webSocket else {
            throw WebSocketConnectionError.webSocketNotFound
        }
        
        let messageData = try encoder.encode(message)

        guard let string = String(bytes: messageData, encoding: .utf8) else {
            throw WebSocketConnectionError.invalidRequest
        }

        log("Send a message: \(message)")

        // Send a message
        try await webSocket.send(.string(string))
        try Task.checkCancellation()

        // Get a message from the last response
        let latestMessage = try await webSocket.receive()
        let response = try mapToData(from: latestMessage)
        try Task.checkCancellation()

        return response
    }
    
    public func disconnect() {
        webSocket?.cancel(with: .goingAway, reason: nil)
        webSocket = nil
    }
}

// MARK: - Private

private extension WebSocketConnection {
    func makeWebSocketTask() {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocket = session.webSocketTask(with: url)
    }
    
    func connect() {
        webSocket?.resume()
    }
    
    func startPingTask() {
        pingTask = Task {
            do {
                try await ping()
            } catch {
                log("Ping task error: \(error)")
            }
        }
    }
    
    func ping() async throws {
        guard webSocket?.state == .running else {
            log("Will not send ping. State: \(String(describing: webSocket?.state))")
            return
        }
        
        log("Send ping")

        if let message = ping.message {
            try await webSocket?.send(.data(message))
        }

        webSocket?.sendPing { [weak self] error in
            self?.log("Receive pong. Error: \(String(describing: error))")
        }
        
        try await Task.sleep(nanoseconds: ping.interval * 1_000_000_000)
        
        try await ping()
    }
    
    func mapToData(from message: URLSessionWebSocketTask.Message) throws -> Data {
        switch message {
        case .data(let data):
            log("Receive a data: \(data)")
            return data
            
        case .string(let string):
            log("Receive a string: \(string)")
            guard let data = string.data(using: .utf8) else {
                throw WebSocketConnectionError.invalidResponse
            }

            return data
            
        @unknown default:
            fatalError()
        }
    }
    
    func log(_ args: Any) {
       print("\(Date()) [\(self)]", args)
   }
}

// MARK: - URLSessionWebSocketDelegate

extension WebSocketConnection: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        log("Connection did open")
        startPingTask()
    }
    
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        log("Connection did close with code: \(closeCode)")
    }
}

// MARK: - Model

extension WebSocketConnection {
    public struct Ping {
        let interval: UInt64
        let message: Data?
    }
}

// MARK: - Error

enum WebSocketConnectionError: Error {
    case webSocketNotFound
    case responseNotFound
    case invalidResponse
    case invalidRequest
}

// MARK: - URLSessionTask.State + CustomStringConvertible

extension URLSessionTask.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .running:
            return "Running"
        case .suspended:
            return "Suspended"
        case .canceling:
            return "Canceling"
        case .completed:
            return "Completed"
        @unknown default:
            fatalError()
        }
    }
}
