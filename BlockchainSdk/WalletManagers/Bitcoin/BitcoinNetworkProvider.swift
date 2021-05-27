//
//  BitcoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 07.04.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct BitcoinFee {
    let minimalSatoshiPerByte: Decimal
    let normalSatoshiPerByte: Decimal
    let prioritySatoshiPerByte: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let hasUnconfirmed: Bool
    let unspentOutputs: [BitcoinUnspentOutput]
}

struct BitcoinUnspentOutput {
    let transactionHash: String
    let outputIndex: Int
    let amount: UInt64
    let outputScript: String
}

enum BitcoinNetworkApi {
    case blockchainInfo
	case blockchair
    case blockcypher
}

protocol BitcoinNetworkProvider: AnyObject {
    var host: String { get }
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error>
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error>
    func getFee() -> AnyPublisher<BitcoinFee, Error>
    func send(transaction: String) -> AnyPublisher<String, Error>
	func getSignatureCount(address: String) -> AnyPublisher<Int, Error>
}


extension BitcoinNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: {
            self.getInfo(address: $0)
        })
    }
}
