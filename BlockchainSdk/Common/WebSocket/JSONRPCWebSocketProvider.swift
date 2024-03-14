//
//  JSONRPCWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class JSONRPCWebSocketProvider {
    private enum Constants {
        static let ping: TimeInterval = 10
        static let timeout: TimeInterval = 30
    }
    
    private let url: URL
    private let versions: [String]
    private let connection: WebSocketConnection
    
    private var requests: [Int: ((Result<Data, Error>) -> Void)] = [:]
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
        
        log("init")
    }
    
    deinit {
        log("deinit")
        cancel()
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
         
        let response: JSONRPCResponse<Result> = try await withCheckedThrowingContinuation { continuation in
            let handler: ((Swift.Result<Data, Error>) -> Void) = { result in
                switch result {
                case .success(let data):
                    do {
                        let response = try decoder.decode(JSONRPCResponse<Result>.self, from: data)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            requests.updateValue(handler, forKey: request.id)
        }

        requests.removeValue(forKey: request.id)
        
        assert(request.id == response.id, "The response contains wrong id")
        log("Return result \(response.result)")

        return response.result
    }
    
    func cancel() {
        // We have to cancel all that release objects
        receiveTask?.cancel()
        receiveTask = nil
        requests.values.forEach { $0(.failure(CancellationError())) }
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
                setupReceiveTask()
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

            if let handler = requests[id] {
                handler(.success(data))
            } else {
                log("Received json: \(String(describing: json)) is not handled")
            }

        } catch {
            log("Receive catch parse error: \(error)")
        }
    }
    
    func log(_ args: Any) {
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
