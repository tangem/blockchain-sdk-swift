//
//  CryptoAPIsUnspentOutputs.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 14.06.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// https://developers.cryptoapis.io/technical-documentation/blockchain-data/unified-endpoints/list-unspent-transaction-outputs-by-address
struct CryptoAPIsUnspentOutputs: Codable {
    /// Represents the unique identifier of a transaction, i.e. it could be transactionId
    /// in UTXO-based protocols like Bitcoin, and transaction hash in Ethereum blockchain.
    let transactionId: String
    let amount: String
    let index: Int
    
    let address: String
    let isConfirmed: Bool
    let timestamp: Date
}
