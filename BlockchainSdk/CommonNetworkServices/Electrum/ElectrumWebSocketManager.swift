//
//  ElectrumWebSocketManager.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//

import Foundation

class ElectrumWebSocketManager: HostProvider {
    var host: String { url.absoluteString }
    
    private let url: URL
    private let webSocketProvider: JSONRPCWebSocketProvider
    
    private let encoder: JSONEncoder = .init()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    init(url: URL) {
        self.url = url
        self.webSocketProvider = JSONRPCWebSocketProvider(url: url)
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
    
    func getTransaction(transactionHash: String) async throws -> ElectrumDTO.Response.Transaction {
        let params: [AnyEncodable] = [AnyEncodable(transactionHash), AnyEncodable(true)]
        return try await send(method: "blockchain.transaction.get", parameter: params)
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
    
    func send<Parameter: Encodable, Result: Decodable>(method: String, parameters: [Parameter]) async throws -> Result {
        try await webSocketProvider.send(
            method: method,
            parameter: parameters,
            encoder: encoder,
            decoder: decoder
        )
    }
}

// MARK: - IdentifierType

extension ElectrumWebSocketManager {
    enum IdentifierType {
        case address(_ address: String)
        case scripthash(_ hash: String)
    }
}

struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    
    public init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
