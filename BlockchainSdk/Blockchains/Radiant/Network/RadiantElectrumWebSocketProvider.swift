//
//  RadiantElectrumWebSocketProvider.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 12.03.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct RadiantElectrumWebSocketProvider: HostProvider {
    var host: String { url.absoluteString }
    
    private let url: URL
    private let connection: JSONRPCWebSocketProvider
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    public init(url: URL) {
        self.url = url

        let request = JSONRPCWebSocketProvider.JSONRPCRequest(id: 0, method: "server.version", params: ["1.19", "1.4"])
        let data = try! JSONEncoder().encode(request)

        connection = JSONRPCWebSocketProvider(url: url, versions: ["1.19", "1.4"])
    }
    
    func getBalance(address: String) async throws -> ElectrumDTO.Response.Balance {
        try await connection.send(
            method: "blockchain.scripthash.get_balance",
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
            method: "blockchain.scripthash.listunspent",
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
