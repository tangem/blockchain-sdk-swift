//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class JSONRPCWebSocketProvider: NSObject {
    private let connection: WebSocketConnection
    private var counter: Int = 0
    
    init(url: URL, keepAliveMessage: Data?) {
        self.connection = .init(url: url, ping: .init(interval: 30, message: keepAliveMessage))
    }
    
    func send<Parameter: Encodable, Result: Decodable>(
        method: String,
        parameter: Parameter,
        decoder: JSONDecoder = .init()
    ) async throws -> Result {
        let request = JSONRPCRequest<Parameter>(id: counter, method: method, params: parameter)
        counter += 1
        
        let data = try await connection.send(request)
        
        try Task.checkCancellation()

        let response = try decoder.decode(JSONRPCResponse<Result>.self, from: data)

        assert(request.id == response.id, "The response contains wrong id")
        
        return response.result
    }
}

// MARK: - Models

extension JSONRPCWebSocketProvider {
    struct JSONRPCRequest<Parameter: Encodable>: Encodable {
        let id: Int
        let method: String
        let params: Parameter
    }
    
    struct JSONRPCResponse<Result: Decodable>: Decodable {
        let id: Int
        let jsonrpc: String
        let result: Result
    }
}
