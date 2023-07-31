//
//  BlockscoutResponceMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct BlockscoutResponseMapper {
    let decimalValue: Decimal

    init(decimalValue: Decimal) {
        self.decimalValue = decimalValue
    }
    
    func mapToTransactionRecord(_ response: BlockscoutTransaction) -> TransactionRecord? {
        guard let amountWei = Decimal(response.value),
              let gasPriceWei = Decimal(response.gasPrice),
              let spentGasWei = Decimal(response.gasUsed) else {
            return nil
        }
        
        let confirmations = Int(response.confirmations) ?? 0

        var date: Date?
        if let timestamp = TimeInterval(response.timeStamp) {
            date = Date(timeIntervalSince1970: timestamp)
        }

        let amount = amountWei / decimalValue
        let feeAmount = (gasPriceWei * spentGasWei) / decimalValue
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: feeAmount))
        
        let destination: TransactionRecord.AddressType
        if !response.contractAddress.isEmpty {
            destination = .contract(response.contractAddress)
        } else {
            destination = .single(response.to)
        }
        
        return TransactionRecord(
            hash: response.hash,
            source: .single(response.from),
            destination: destination,
            amount: Amount(with: .ethereum(testnet: false), value: amount),
            fee: fee,
            status: confirmations > 0 ? .confirmed : .unconfirmed,
            type: .send,
            date: date
        ) 
    }
}
