//
//  BlockscoutResponse.swift
//  BlockchainSdk
//
//  Created by Andrew Son on 10/02/23.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BlockscoutResponse<T: Decodable>: Decodable {
    let message: String
    let status: String
    let result: T
}

struct BlockscoutTransaction: Decodable {
    let blockHash: String
    let blockNumber: String
    let confirmations: String
    let contractAddress: String
    /// Gas limit in Wei
    let gas: String
    let gasPrice: String
    let gasUsed: String
    
    let hash: String
    let from: String
    let to: String
    /// Sent amount in Wei
    let value: String
    let timeStamp: String
    let nonce: String
    let transactionIndex: String
    
    let isError: String?
}

extension BlockscoutTransaction: TransactionHistoryRecordConvertible {
    var sourceAddress: String { from }
    
    var destinationAddress: String { to }
    
    var status: TransactionStatus {
        let confirmations = Int(confirmations) ?? 0
        return confirmations > 0 ? .confirmed : .unconfirmed
    }
    
    var date: Date? {
        guard let timestamp = TimeInterval(timeStamp) else { return nil }
        
        return Date(timeIntervalSince1970: timestamp)
    }
    
    var tokenContractAddress: String? { contractAddress }
    
    func amount(decimalCount: Int) -> Decimal? {
        guard let amountWei = Decimal(value) else {
            return nil
        }
        
        return amountWei / pow(10, decimalCount)
    }
    
    func fee(decimalCount: Int) -> Decimal? {
        guard let gasPriceWei = Decimal(gasPrice),
              let spentGasWei = Decimal(gasUsed)
        else { return nil }
        
        return (gasPriceWei * spentGasWei) / pow(10, decimalCount)
    }
}
