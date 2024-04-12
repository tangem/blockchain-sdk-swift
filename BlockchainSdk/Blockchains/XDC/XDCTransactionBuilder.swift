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

    override func buildForSign(transaction: Transaction) throws -> Data {
        let copyTransaction = transaction.then { tx in
            tx.sourceAddress = addressConverter.convertToETHAddress(transaction.sourceAddress)
            tx.destinationAddress = addressConverter.convertToETHAddress(transaction.destinationAddress)
            tx.changeAddress = addressConverter.convertToETHAddress(transaction.changeAddress)
            tx.contractAddress = transaction.contractAddress.map { addressConverter.convertToETHAddress($0) }
            // TODO: contractAddress 
        }

        return try super.buildForSign(transaction: copyTransaction)
    }

    override func buildForTokenTransfer(destination: String, amount: Amount) throws -> Data {
        let convertedTargetAddress = addressConverter.convertToETHAddress(destination)
        return try super.buildForTokenTransfer(destination: convertedTargetAddress, amount: amount)
    }
}
