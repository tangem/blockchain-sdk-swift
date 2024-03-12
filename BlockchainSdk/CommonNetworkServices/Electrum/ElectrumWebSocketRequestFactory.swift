//
//  ElectrumWebSocketRequestFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//

import Foundation

public class ElectrumWebSocketManager: HostProvider {
    var host: String { url.absoluteString }
    
    private let url: URL
    
    private lazy var connection: JSONRPCWebSocketProvider = {
        .init(url: url, versions: ["1.4.3"])
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    public init(url: URL) {
        self.url = url
    }
    
    func getBalance(address: String) async throws -> ElectrumDTO.Response.Balance {
        try await connection.send(
            method: "blockchain.address.get_balance",
            parameter: [address],
            decoder: decoder
        )
    }

    func getTxHistory(address: String) async throws -> ElectrumDTO.Response.History {
        try await connection.send(
            method: "blockchain.address.get_history",
            parameter: [address],
            decoder: decoder
        )
    }
    
    func getUnspents(address: String) async throws -> [ElectrumDTO.Response.ListUnspent] {
        try await connection.send(
            method: "blockchain.address.listunspent",
            parameter: [address],
            decoder: decoder
        )
    }
    
    func send(transactionHex: String) async throws -> ElectrumDTO.Response.Broadcast {
        try await connection.send(
            method: "blockchain.transaction.broadcast",
            parameter: transactionHex,
            decoder: decoder
        )
    }

    func estimateFee(block: Int) async throws -> Int {
        try await connection.send(
            method: "blockchain.estimatefee",
            parameter: [block],
            decoder: decoder
        )
    }
}
