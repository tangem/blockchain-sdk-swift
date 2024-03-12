//
//  ElectrumWebSocketRequestFactory.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 11.03.2024.
//

import Foundation

let nexaURLs: [String] = [
    "wss://onekey-electrum.bitcoinunlimited.info:20004",
    "wss://electrum.nexa.org:20004"
]

public class ElectrumWebSocketManager: HostProvider {
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

        let request = JSONRPCWebSocketProvider.JSONRPCRequest(id: 0, method: "server.version", params: [ "1.9.5", "0.6" ])
        let data = try! JSONEncoder().encode(request)

        connection = .init(url: url, keepAliveMessage: data)
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
    
    func getUnspents(address: String) async throws -> ElectrumDTO.Response.ListUnspent {
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
