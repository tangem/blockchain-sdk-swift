//
//  XDCTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by Alexander Osokin on 17.01.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

class XDCTransactionBuilder: EthereumTransactionBuilder {
    private let addressConverter = XDCAddressConverter()

    override func buildForSign(transaction: Transaction, nonce: Int) -> CompiledEthereumTransaction? {
        let copyTransaction = transaction.then { tx in
            tx.sourceAddress = addressConverter.convertToETHAddress(transaction.sourceAddress)
            tx.destinationAddress = addressConverter.convertToETHAddress(transaction.destinationAddress)
            tx.changeAddress = addressConverter.convertToETHAddress(transaction.changeAddress)
            tx.contractAddress = transaction.contractAddress.map { addressConverter.convertToETHAddress($0) }
        }

        return super.buildForSign(transaction: copyTransaction, nonce: nonce)
    }

    override func getData(for amount: Amount, targetAddress: String) -> Data? {
        let convertedTargetAddress = addressConverter.convertToETHAddress(targetAddress)
        return super.getData(for: amount, targetAddress: convertedTargetAddress)
    }
}
