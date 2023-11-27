//
//  DecimalTransactionBuilder.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 27.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

class DecimalTransactionBuilder: EthereumTransactionBuilder {
    private let addressConverter = DecimalBlockchainAddressConverter()
    
    override func buildForSign(transaction: Transaction, nonce: Int) -> CompiledEthereumTransaction? {
        let sourceConvertedAddress = convertAddressIfNeeded(destinationAddress: transaction.sourceAddress)
        let destinationConvertedAddress = convertAddressIfNeeded(destinationAddress: transaction.destinationAddress)
        
        let copyTransaction = transaction.then { trx in
            trx.sourceAddress = sourceConvertedAddress
            trx.destinationAddress = destinationConvertedAddress
        }
        
        return super.buildForSign(transaction: copyTransaction, nonce: nonce)
    }
    
    // MARK: - Private Implementation
    
    private func convertAddressIfNeeded(destinationAddress: String) -> String {
        return addressConverter.convertDscAddressToErcAddress(addressHex: destinationAddress) ?? destinationAddress
    }
}
