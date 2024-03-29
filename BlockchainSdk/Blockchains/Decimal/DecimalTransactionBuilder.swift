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
        do {
            let sourceConvertedAddress = try convertAddressIfNeeded(destinationAddress: transaction.sourceAddress)
            let destinationConvertedAddress = try convertAddressIfNeeded(destinationAddress: transaction.destinationAddress)
            
            let copyTransaction = transaction.then { tx in
                tx.sourceAddress = sourceConvertedAddress
                tx.destinationAddress = destinationConvertedAddress
            }
            
            return super.buildForSign(transaction: copyTransaction, nonce: nonce)
        } catch {
            return nil
        }
    }
    
    override func getData(for amount: Amount, targetAddress: String) -> Data? {
        do {
            let convertedTargetAddress = try convertAddressIfNeeded(destinationAddress: targetAddress)
            return super.getData(for: amount, targetAddress: convertedTargetAddress)
        } catch {
            return nil
        }
    }
    
    // MARK: - Private Implementation
    
    private func convertAddressIfNeeded(destinationAddress: String) throws -> String {
        try addressConverter.convertDecimalBlockchainAddressToDscAddress(addressHex: destinationAddress)
    }
}
