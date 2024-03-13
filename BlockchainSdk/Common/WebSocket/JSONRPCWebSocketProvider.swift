//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class JSONRPCWebSocketProvider {
    private let url: URL
    private let versions: [String]
    private let connection: WebSocketConnection
    
    private var requests: [Int: CheckedContinuation<Data, Never>] = [:]
    private var receiveTask: Task<Void, Never>?
    private var counter: Int = 0
    
    init(url: URL, versions: [String]) {
        self.url = url
        self.versions = versions
        
        let message = try! JSONRPCRequest(id: -1, method: "server.ping", params: [String]()).string()
        
        connection = WebSocketConnection(
            url: url,
            ping: .message(interval: 10, message: .string(message)),
            timeout: 30
        )
    }
    
    func receive() {
        receiveTask = Task {
            do {
                let data = try await connection.receive()
                
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let id = json["id"] as? Int else {
                    return
                }

                requests[id]!.resume(returning: data)
                
                // Handle next message
                receive()
            } catch {
                await self.connection.disconnect()
            }
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
}

// MARK: - Models

extension JSONRPCWebSocketProvider: CustomStringConvertible {
    nonisolated var description: String {
        objectDescription(self)
    }
}

func objectDescription(
    _ object: AnyObject,
    userInfo: KeyValuePairs<AnyHashable, Any> = [:]
) -> String {
    let typeName = String(describing: type(of: object))
    let memoryAddress = String(describing: Unmanaged.passUnretained(object).toOpaque())
    let description = userInfo.reduce(into: [typeName + ": " + memoryAddress]) { partialResult, pair in
        partialResult.append(String(describing: pair.key) + " = " + String(describing: pair.value))
    }

    return "<" + description.joined(separator: "; ") + ">"
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
