//
//  DecimalWalletManager.swift
//  BlockchainSdk
//
//  Created by skibinalexander on 15.11.2023.
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemSdk

final class DecimalWalletManager: EthereumWalletManager {
    
    override var allowsFeeSelection: Bool { false }
    
    override func sign(_ transaction: Transaction, signer: TransactionSigner) -> AnyPublisher<String, Error> {
        let convertedDestinationAddress = convertAddress(destinationAddress: transaction.destinationAddress)
        
        let copyTransaction = Transaction(
            amount: transaction.amount,
            fee: transaction.fee,
            sourceAddress: transaction.sourceAddress,
            destinationAddress: convertedDestinationAddress,
            changeAddress: transaction.changeAddress,
            params: transaction.params
        )
        
        return super.sign(copyTransaction, signer: signer)
    }
    
    // MARK: - Private Implementation

    private func convertAddress(destinationAddress: String) -> String {
        return DecimalUtils().convertDscAddressToErcAddress(addressHex: destinationAddress) ?? destinationAddress
    }
    
}

