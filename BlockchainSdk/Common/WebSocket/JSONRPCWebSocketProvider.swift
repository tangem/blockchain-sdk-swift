//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class JSONRPCWebSocketProvider {
    private lazy var connection: WebSocketConnection = {
        let message = try! JSONRPCRequest(id: counter, method: "server.ping", params: [String]()).string()
        
        return WebSocketConnection(
            url: url,
            ping: .message(interval: 10, message: .string(message)),
            timeout: 30
        )
    }()

    private let url: URL
    private let versions: [String]
    
    private var counter: Int = 0
    
    init(url: URL, versions: [String]) {
        self.url = url
        self.versions = versions
    }
    
    func send<Parameter: Encodable, Result: Decodable>(
        method: String,
        parameter: Parameter,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) async throws -> Result {
        let request = makeJSONRPCRequest(method: method, parameter: parameter)
        let string = try request.string(encoder: encoder)
        let data = try await connection.send(.string(string))
        
        try Task.checkCancellation()

        let response = try decoder.decode(JSONRPCResponse<Result>.self, from: data)
        assert(request.id == response.id, "The response contains wrong id")
        
        return response.result
    }
}

// MARK: - Private

private extension JSONRPCWebSocketProvider {
    func makeJSONRPCRequest<Parameter: Encodable>(method: String, parameter: Parameter) -> JSONRPCRequest<Parameter> {
       let request = JSONRPCRequest<Parameter>(id: counter, method: method, params: parameter)
       counter += 1
       return request
   }
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
                throw WebSocketConnectionError.invalidRequest
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
