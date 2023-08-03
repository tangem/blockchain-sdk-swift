//
//  BlockscoutResponseMapper.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 25.07.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

// Will be changed in https://tangem.atlassian.net/browse/IOS-3979
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

        let date: Date?
        if let timestamp = TimeInterval(response.timeStamp) {
            date = Date(timeIntervalSince1970: timestamp)
        } else {
            date = nil
        }

        let amount = Amount(with: .saltPay, value: amountWei / decimalValue)
        let feeAmount = (gasPriceWei * spentGasWei) / decimalValue
        let fee = Fee(Amount(with: .saltPay, value: feeAmount))
        
        let destinationAddress: TransactionRecord.Destination.Address
        if !response.contractAddress.isEmpty {
            destinationAddress = .contract(response.contractAddress)
        } else {
            destinationAddress = .user(response.to)
        }
        
        let source = TransactionRecord.Source(address: response.from, amount: amount)
        let destination = TransactionRecord.Destination(address: destinationAddress, amount: amount)
        
        return TransactionRecord(
            hash: response.hash,
            source: .single(source),
            destination: .single(destination),
            fee: fee,
            status: confirmations > 0 ? .confirmed : .unconfirmed,
            type: .send,
            date: date
        )
    }
}
