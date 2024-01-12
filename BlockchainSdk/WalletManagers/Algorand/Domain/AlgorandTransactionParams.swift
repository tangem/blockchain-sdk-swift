//
//  AlgorandTransactionParams.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 09.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public enum AlgorandTransactionParams {
    public struct Input: TransactionParams {
        public let nonce: String
        
        public init(nonce: String) {
            self.nonce = nonce
        }
    }
    
    struct Build {
        let publicKey: Wallet.PublicKey
        let genesisId: String
        let genesisHash: String
        let round: UInt64
        let lastRound: UInt64
        let nonce: String?
    }
}
