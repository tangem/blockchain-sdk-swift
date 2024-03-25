//
//  ElectrumWebSocketManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//

import Foundation

class ElectrumWebSocketProvider: HostProvider {
    var host: String { webSocketProvider.host }
    
    private let webSocketProvider: JSONRPCWebSocketProvider
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(url: URL) {
        let ping: WebSocketConnection.Ping = {
            do {
                let request = JSONRPCWebSocketProvider.JSONRPCRequest(id: -1, method: "server.ping", params: [String]())
                let message = try request.string(encoder: .init())
                return .message(interval: Constants.pingInterval, message: .string(message))
            } catch {
                return .plain(interval: Constants.pingInterval)
            }
        }()
        
        webSocketProvider = JSONRPCWebSocketProvider(url: url, ping: ping, timeoutInterval: Constants.timeoutInterval)
    }
    
    func getBalance(identifier: IdentifierType) async throws -> ElectrumDTO.Response.Balance {
        switch identifier {
        case .address(let address):
            return try await send(method: "blockchain.address.get_balance", parameter: [address])
        case .scripthash(let scripthash):
            return try await send(method: "blockchain.scripthash.get_balance", parameter: [scripthash])
        }
    }
    
    func getTxHistory(identifier: IdentifierType) async throws -> [ElectrumDTO.Response.History] {
        switch identifier {
        case .address(let address):
            return try await send(method: "blockchain.address.get_history", parameter: [address])
        case .scripthash(let scripthash):
            return try await send(method: "blockchain.scripthash.get_history", parameter: [scripthash])
        }
    }
    
    func getUnspents(identifier: IdentifierType) async throws -> [ElectrumDTO.Response.ListUnspent] {
        switch identifier {
        case .address(let address):
            return try await send(method: "blockchain.address.listunspent", parameter: [address])
        case .scripthash(let scripthash):
            return try await send(method: "blockchain.scripthash.listunspent", parameter: [scripthash])
        }
    }
    
    func send(transactionHex: String) async throws -> ElectrumDTO.Response.Broadcast {
        try await send(method: "blockchain.transaction.broadcast", parameter: transactionHex)
    }
    
    func estimateFee(block: Int) async throws -> Int {
        try await send(method: "blockchain.estimatefee", parameter: [block])
    }
}

// MARK: - Private

private extension ElectrumWebSocketManager {
    func send<Parameter: Encodable, Result: Decodable>(method: String, parameter: Parameter) async throws -> Result {
        try await webSocketProvider.send(
            method: method,
            parameter: parameter,
            encoder: encoder,
            decoder: decoder
        )
    }
}

// MARK: - IdentifierType

extension ElectrumWebSocketManager {
    private enum Constants {
        static let pingInterval: TimeInterval = 10
        static let timeoutInterval: TimeInterval = 60
    }
    
    enum IdentifierType {
        case address(_ address: String)
        case scripthash(_ hash: String)
    }
}
