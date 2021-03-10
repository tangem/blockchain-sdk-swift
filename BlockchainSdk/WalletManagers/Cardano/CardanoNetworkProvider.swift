//
//  CardanoNetworkProvider.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardanoNetworkProvider {
    func getInfo(address: String) -> AnyPublisher<CardanoAddressResponse, Error>
    func send(base64EncodedTx: String) -> AnyPublisher<String, Error>
}

public struct CardanoAddressResponse {
    let balance: Decimal
    let transactionList: [String]
    let unspendOutputs: [CardanoUnspentOutput]
}

public struct CardanoUnspentOutput {
    let address: String
    let amount: Decimal
    let outputIndex: Int
    let transactionHash: Data
}
