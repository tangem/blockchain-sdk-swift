//
//  UTXOTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Sergey Balashov on 07.06.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BitcoinCore

protocol UTXOTransactionBuilder {
    func update(feeRates: [Decimal: Int])
    func update(unspentOutputs: [BitcoinUnspentOutput])

    func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, changeScript: Data?, sequence: Int?) -> Decimal

    func buildForSign(transaction: Transaction, sequence: Int?, sortType: TransactionDataSortType) throws -> [Data]
    func buildForSend(transaction: Transaction, signatures: [Signature], sequence: Int?, sortType: TransactionDataSortType) throws -> Data
}

extension UTXOTransactionBuilder {
    func fee(for value: Decimal, address: String?, feeRate: Int, senderPay: Bool, sequence: Int? = nil) -> Decimal {
        fee(for: value, address: address, feeRate: feeRate, senderPay: senderPay, changeScript: nil, sequence: sequence)
    }

    func buildForSign(transaction: Transaction, sequence: Int?) throws -> [Data] {
        try buildForSign(transaction: transaction, sequence: sequence, sortType: .bip69)
    }

    func buildForSend(transaction: Transaction, signatures: [Signature], sequence: Int?) throws -> Data {
        try buildForSend(transaction: transaction, signatures: signatures, sequence: sequence, sortType: .bip69)
    }
}
