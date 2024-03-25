//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor JSONRPCWebSocketProvider {
    private let url: URL
    private let connection: WebSocketConnection
    
    // Internal
    private var requests: [Int: CheckedContinuation<Data, Error>] = [:]
    private var receiveTask: Task<Void, Never>?
    private var counter: Int = 0

    init(url: URL, ping: WebSocketConnection.Ping, timeoutInterval: TimeInterval) {
        self.url = url
        connection = WebSocketConnection(url: url, ping: ping, timeout: timeoutInterval)
    }
     
    func send<Parameter: Encodable, Result: Decodable>(
        method: String,
        parameter: Parameter,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) async throws -> Result {
        counter += 1
        let request = JSONRPCRequest(id: counter, method: method, params: parameter)
        try await connection.send(.string(request.string(encoder: encoder)))
        
        // setup handler for message
        setupReceiveTask()
         
        let data: Data = try await withCheckedThrowingContinuation { continuation in
            requests.updateValue(continuation, forKey: request.id)
        }

        // Remove the fulfilled `continuation` from cache
        requests.removeValue(forKey: request.id)
        let response = try decoder.decode(JSONRPCResponse<Result>.self, from: data)
        
        assert(request.id == response.id, "The response contains wrong id")
        log("Return result \(response.result)")

        return response.result
    }
    
    func cancel() {
        receiveTask?.cancel()
        requests.values.forEach { $0.resume(throwing: CancellationError()) }
    }
}

// MARK: - Private

private extension JSONRPCWebSocketProvider {
    func setupReceiveTask() {
        receiveTask = Task { [weak self] in
            guard let self else { return }
            
            do {
                let data = try await connection.receive()
                await proceedReceive(data: data)
                
                // Handle next message
                await setupReceiveTask()
            } catch {
                log("ReceiveTask catch error: \(error)")
            }
        }
    }
    
    func proceedReceive(data: Data) async {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let id = json?["id"] as? Int else {
                return
            }

            if let continuation = requests[id] {
                continuation.resume(returning: data)
            } else {
                log("Received json: \(String(describing: json)) is not handled")
            }

        } catch {
            log("Receive catch parse error: \(error)")
        }
    }
    
    nonisolated func log(_ args: Any) {
        print("\(self) [\(args)]")
   }
}

// MARK: - HostProvider

extension JSONRPCWebSocketProvider: HostProvider {
    nonisolated var host: String { url.absoluteString }
}

// MARK: - CustomStringConvertible

extension JSONRPCWebSocketProvider: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

// MARK: - Error

enum JSONRPCWebSocketProviderError: Error {
    case invalidRequest
}

// MARK: - Models

extension JSONRPCWebSocketProvider {
    struct JSONRPCRequest<Parameter: Encodable>: Encodable {
        let id: Int
        let method: String
        let params: Parameter
        
        func string(encoder: JSONEncoder = .init()) throws -> String {
            let messageData = try encoder.encode(self)

            guard let string = String(bytes: messageData, encoding: .utf8) else {
                throw JSONRPCWebSocketProviderError.invalidRequest
            }
            
            return string
        }
    }
    
    struct JSONRPCResponse<Result: Decodable>: Decodable {
        let id: Int
        let jsonrpc: String
        let result: Result
    }
}
