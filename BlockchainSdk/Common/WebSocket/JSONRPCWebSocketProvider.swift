//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

actor JSONRPCWebSocketProvider {
    private enum Constants {
        static let ping: TimeInterval = 10
        static let timeout: TimeInterval = 30
    }
    
    private let url: URL
    private let versions: [String]
    private let connection: WebSocketConnection
    
    private var requests: [Int: CheckedContinuation<Data, Never>] = [:]
    private var receiveTask: Task<Void, Error>?
    private var counter: Int = 0

    init(url: URL, versions: [String]) {
        self.url = url
        self.versions = versions
        
        let message = try! JSONRPCRequest(id: -1, method: "server.ping", params: [String]()).string()
        
        connection = WebSocketConnection(
            url: url,
            ping: .message(interval: Constants.ping, message: .string(message)),
            timeout: Constants.timeout
        )
    }
    
    deinit {
        log("deinit \(self)")
        Task { await connection.disconnect() }
    }
    
    func receive() {
        receiveTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            let data = try await self.connection.receive()
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let id = json?["id"] as? Int,
                  let continuation = await self.requests[id] else {
                self.log("Received json: \(String(describing: json)) is not handled")
                return
            }
            
            continuation.resume(returning: data)

            // Handle next message
            await self.receive()
        }
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
        receive()
         
        let data = await withCheckedContinuation { continuation in
            requests.updateValue(continuation, forKey: request.id)
        }
        
        let response = try decoder.decode(JSONRPCResponse<Result>.self, from: data)
        assert(request.id == response.id, "The response contains wrong id")
        
        return response.result
    }
}

// MARK: - Private

private extension JSONRPCWebSocketProvider {
    nonisolated func log(_ args: Any) {
        print("\(self) [\(args)]")
   }
}

// MARK: - Models

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
